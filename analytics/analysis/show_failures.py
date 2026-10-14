"""Print the rows behind the dbt tests that failed in the latest run.

dbt records each test's outcome, and the table its failing rows were stored in
(`store_failures: true` in dbt_project.yml), in `run_results.json`. Plain dbt
writes it to `target/`; Dagster writes one per run under `target/<asset>-<id>/`.
Taking the newest file covers both, and reading the table names from it means
stale audit tables left by renamed tests are never shown.

Tests that *errored* (bad SQL, missing table) produced no rows, so they are
only counted, not shown.
"""

import json
import os
from pathlib import Path

import duckdb

target = Path("target")
runs = sorted(target.rglob("run_results.json"), key=lambda p: p.stat().st_mtime)
if not runs:
    raise SystemExit("No run_results.json under target/ -- run `just build` or `just setup` first.")

results = json.loads(runs[-1].read_text())["results"]
failed = [r for r in results if r["status"] in ("fail", "warn") and r.get("relation_name")]
errored = [r for r in results if r["status"] == "error"]

con = duckdb.connect(os.environ["DATABASE_NAME"], read_only=True)

for result in failed:
    print(f"\n{result['unique_id'].split('.')[2]}: {result['failures']} failing row(s)")
    con.sql(f"select * from {result['relation_name']}").show()

if errored:
    print(f"\n{len(errored)} test(s) errored and have no rows to show; see the dbt output above.")
if not failed and not errored:
    print("No failing tests in the latest run.")
