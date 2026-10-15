import os
from pathlib import Path

from dagster import AssetKey, MaterializeResult, asset
from dagster_duckdb import DuckDBResource

# Each source's raw tables, by the name of the dbt source that declares them.
# The CSV is `<table>.csv` in WSL_RAW_DIR and lands in the shared `raw` schema,
# so a table name must be unique across sources.
SOURCES = {
    "bbc_sport": [
        "matches",
        "match_teams",
        "match_players",
        "match_player_cards",
        "match_officials",
        "match_pitch_layout",
        "match_actions",
        "player_match_stats",
        "team_match_stats",
        "fixtures",
    ],
    "wsl_football": [
        "squad_players",
    ],
}


def build_raw_asset(source: str, table: str) -> asset:
    @asset(
        key=AssetKey([source, table]),
        group_name="raw_ingestion",
    )
    def _asset(duckdb: DuckDBResource) -> MaterializeResult:
        csv = Path(os.environ["WSL_RAW_DIR"]).joinpath(f"{table}.csv")
        with duckdb.get_connection() as conn:
            conn.execute("create schema if not exists raw")
            conn.execute(
                f"create or replace table raw.{table} as "
                "select * from read_csv(?, all_varchar = true)",
                [str(csv)],
            )
            rows = conn.execute(f"select count(*) from raw.{table}").fetchone()[0]
        return MaterializeResult(metadata={"rows": rows})

    return _asset


raw_assets = [
    build_raw_asset(source, table)
    for source, tables in SOURCES.items()
    for table in tables
]
