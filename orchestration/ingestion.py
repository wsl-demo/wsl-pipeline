import os
from pathlib import Path

from dagster import AssetKey, MaterializeResult, asset
from dagster_duckdb import DuckDBResource

TABLES = [
    "matches",
    "match_teams",
    "match_players",
    "match_player_cards",
    "match_officials",
    "match_pitch_layout",
    "match_actions",
    "player_match_stats",
    "team_match_stats",
]


def build_raw_asset(table: str) -> asset:
    @asset(
        key=AssetKey(["bbc_sport", table]),
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


raw_assets = [build_raw_asset(table) for table in TABLES]
