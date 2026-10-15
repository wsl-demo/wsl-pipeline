"""Copy the finished marts into the app's Postgres.

Only marts cross this boundary: raw, staging and intermediate stay in DuckDB.
The app owns two schemas for the pipeline (see its deploy/db-init/):

    analytics_next   staging area; a publish loads every table here first
    analytics        what the API reads

Tables are loaded into analytics_next and then moved into analytics in one
statement batch, so a reader sees either the whole old set or the whole new
set, never a mix. The `pipeline_writer` role can touch only these two schemas.
"""

import os
from contextlib import contextmanager

from dagster import AssetKey, MaterializeResult, asset
from dagster_duckdb import DuckDBResource

# dbt's `marts` folder, built into DuckDB's `main` schema by the default target.
SOURCE_SCHEMA = "main_marts"
TABLES = [
    "matches",
    "matchday_squad_members",
    "players",
    "seasons",
    "squad_members",
    "teams",
]


def _literal(value: str) -> str:
    """A SQL string literal; ATTACH and CALL cannot take bound parameters."""
    return "'" + value.replace("'", "''") + "'"


def _connection_string() -> str:
    """Everything but the password, which travels in PGPASSWORD instead.

    The string goes into SQL text, and SQL text ends up in logs and error
    messages, so a secret in it can leak.
    """
    parts = {
        "host": os.environ.get("PUBLISH_PG_HOST", "localhost"),
        "port": os.environ.get("PUBLISH_PG_PORT", "5432"),
        "dbname": os.environ["PUBLISH_PG_DB"],
        "user": os.environ["PUBLISH_PG_USER"],
    }
    return " ".join(f"{k}={v}" for k, v in parts.items())


@contextmanager
def _password_in_environment():
    """Expose the password to libpq as PGPASSWORD for the duration of a publish.

    The Postgres extension may open further connections while it copies, so the
    variable has to outlast the ATTACH; it is put back afterwards.
    """
    previous = os.environ.get("PGPASSWORD")
    os.environ["PGPASSWORD"] = os.environ["PUBLISH_PG_PASSWORD"]
    try:
        yield
    finally:
        if previous is None:
            os.environ.pop("PGPASSWORD", None)
        else:
            os.environ["PGPASSWORD"] = previous


@asset(
    key=AssetKey("publish_marts"),
    deps=[AssetKey(["marts", table]) for table in TABLES],
    group_name="publish",
)
def publish_marts(duckdb: DuckDBResource) -> MaterializeResult:
    rows = {}
    with _password_in_environment(), duckdb.get_connection() as conn:
        conn.execute("install postgres")
        conn.execute("load postgres")
        conn.execute(f"attach {_literal(_connection_string())} as app (type postgres)")

        for table in TABLES:
            conn.execute(f'drop table if exists app.analytics_next."{table}"')
            conn.execute(
                f'create table app.analytics_next."{table}" as '
                f'select * from {SOURCE_SCHEMA}."{table}"'
            )
            rows[table] = conn.execute(
                f'select count(*) from {SOURCE_SCHEMA}."{table}"'
            ).fetchone()[0]

        swap = "; ".join(
            f'drop table if exists analytics."{table}" cascade; '
            f'alter table analytics_next."{table}" set schema analytics'
            for table in TABLES
        )
        conn.execute(f"call postgres_execute('app', {_literal(swap)})")

    return MaterializeResult(metadata={f"rows_{t}": n for t, n in rows.items()})
