"""Print the rows behind the dbt tests that failed in the latest run.

dbt records each test's outcome, and the table its failing rows were stored in
(`store_failures: true` in dbt_project.yml), in `run_results.json`. Plain dbt
writes it to `target/`; Dagster writes one per run under `target/<asset>-<id>/`.
Taking the newest file covers both, and reading the table names from it means
stale audit tables left by renamed tests are never shown.

Nodes that *errored* produced no rows to show: a model that failed to build
(a contract mismatch, say) or a test with bad SQL. They are listed with their
error message instead, along with how many nodes were skipped because of them.
"""

import json
import os
from pathlib import Path

import duckdb

target = Path("target")
runs = sorted(target.rglob("run_results.json"), key=lambda p: p.stat().st_mtime)
if not runs:
    raise SystemExit(
        "No run_results.json under target/ -- run `just build` or `just publish` first."
    )

results = json.loads(runs[-1].read_text())["results"]
failed = [
    r for r in results if r["status"] in ("fail", "warn") and r.get("relation_name")
]
errored = [r for r in results if r["status"] == "error"]
skipped = [r for r in results if r["status"] == "skipped"]

con = duckdb.connect(os.environ["DATABASE_NAME"], read_only=True)

for result in failed:
    print(f"\n{result['unique_id'].split('.')[2]}: {result['failures']} failing row(s)")
    con.sql(f"select * from {result['relation_name']}").show()

if errored:
    print(f"\n{len(errored)} node(s) errored and produced no rows:")
    for result in errored:
        kind, _, name = result["unique_id"].split(".", 2)
        lines = [l for l in (result.get("message") or "").splitlines() if l.strip()]
        print(f"\n  [{kind}] {name.split('.')[-1]}")
        for line in lines[:12]:
            print(f"    {line}")
        if len(lines) > 12:
            print(f"    ... ({len(lines) - 12} more lines in the dbt log)")
if skipped:
    print(f"\n{len(skipped)} node(s) were skipped because something upstream failed.")
if not failed and not errored:
    print("No failing tests in the latest run.")
