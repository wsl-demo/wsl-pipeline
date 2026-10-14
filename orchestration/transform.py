from pathlib import Path

from dagster import AssetExecutionContext
from dagster_dbt import DbtCliResource, DbtProject, dbt_assets

DBT_DIR = Path(__file__).resolve().parent.parent.joinpath("analytics")

dbt_project = DbtProject(project_dir=DBT_DIR)
dbt_project.prepare_if_dev()  # runs `dbt parse` in dev so a manifest exists


@dbt_assets(manifest=dbt_project.manifest_path)
def wsl_dbt_assets(context: AssetExecutionContext, dbt: DbtCliResource):
    yield from dbt.cli(["build"], context=context).stream()
