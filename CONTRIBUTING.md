# Contributing

Raw CSVs are ingested by Dagster into DuckDB's `raw` schema, then dbt turns
them into staging, intermediate and mart models. Run `just` to list commands.

## Setup

1. Install [uv](https://docs.astral.sh/uv/) and [just](https://just.systems/), then run `uv sync`.
2. Copy `.env.example` to `.env` and set:
   - `WSL_RAW_DIR`: directory holding the source data CSV files (absolute, or relative to the repo root).
   - `DATABASE_NAME`: DuckDB file created in `analytics/`.
3. Run `just setup` to ingest the CSVs and build every model.

## Building a model

1. **Ingest the data.** For a new raw table, add its name to `TABLES` in
   `orchestration/ingestion.py`, then declare it under `sources` in
   `analytics/models/staging/bbc_sport/_bbc_sport__sources.yml`.
2. **Write the model** in the layer it belongs to:

   | Layer | Folder | Job |
   | --- | --- | --- |
   | Staging | `models/staging/` | One model per raw table: rename, cast, parse. No business rules. |
   | Intermediate | `models/intermediate/` | Joins, reshaping and derived logic. |
   | Marts | `models/marts/` | Business-facing entities. |

   Reference raw tables with `source()` and everything else with `ref()`.
   Raw columns are all `varchar`, so staging is where types are set.
3. **Document and test it** in the YAML beside the model: a description, plus
   `unique` / `not_null` on keys and `accepted_values` on categories.
4. **Build it:** `just build --select my_model+` builds the model and its downstream models, with tests.
5. **Inspect it:** `just show my_model` previews rows.
6. **Debug failures:** `just failures` prints the rows behind failed tests
   from the latest run. Tests that errored (rather than failed) show in the dbt output.

## ID convention: URN prefixes

BBC identifies players, teams and so on with URNs such as
`urn:bbc:sportsdata:football:player:s-bxrfg32lc9sspg2ewx160yqxh`. The prefix is
constant per entity type, so it only hurts readability.

- **Raw keeps full URNs**, exactly as received.
- **Staging strips the prefix** with the `strip_urn` macro, and names the column
  `*_id` (`player_id`, `team_id`, `venue_id`) because it is no longer a URN.
- **Everything downstream uses the short ids**, so never join a staged id to a raw URN.

```sql
{{ analytics.strip_urn('"playerUrn"', 'player') }} AS player_id
```

The `kind` is `player`, `team`, `event` (a match, as `event_id`, which differs
from the short `match_id`), `tournament`, `venue` or `official`.

The macro only shortens values that start with the exact prefix and passes
anything else through untouched. `tests/staged_ids_have_no_urn_prefix.sql` then
fails on it, so mixed formats can't reach the marts. When you stage a new
URN column, add it to that test.

## Before pushing a commit

- `just build` passes with no failures, and `just failures` reports none.
- `just docs` renders the lineage you expect.
- Change dbt YAML or SQL, then run `just setup` (not only Dagster) so
  Dagster's manifest is refreshed.

## Useful commands

| Command | Purpose |
| --- | --- |
| `just setup` | Ingest raw data and build all models; creates the warehouse. |
| `just dagster` | Dagster UI at <http://localhost:3000> for runs, lineage and asset checks. |
| `just build [args]` | `dbt build`, e.g. `--select stg_bbc_sport__matches+`. |
| `just failures` | Show rows behind failing tests. |
| `just docs` | Generate and serve the dbt docs site. |
| `just dbeaver` | Open the warehouse in DBeaver. |
| `just dbt <cmd>` | Run any other dbt command. |

DuckDB allows one writer at a time, so **disconnect in DBeaver before running
`just setup`, `just build` or Dagster**, or they fail with `Could not set lock on file`.

To start over, delete `analytics/$DATABASE_NAME` and run `just setup`.
