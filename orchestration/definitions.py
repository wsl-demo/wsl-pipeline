import os

from dagster import Definitions
from dagster_dbt import DbtCliResource
from dagster_duckdb import DuckDBResource

from orchestration.ingestion import raw_assets
from orchestration.publish import publish_marts
from orchestration.transform import DBT_DIR, dbt_project, wsl_dbt_assets

DATABASE = str(DBT_DIR.joinpath(os.environ["DATABASE_NAME"]))

defs = Definitions(
    assets=[*raw_assets, wsl_dbt_assets, publish_marts],
    resources={
        "duckdb": DuckDBResource(database=DATABASE),
        "dbt": DbtCliResource(project_dir=dbt_project),
    },
)
