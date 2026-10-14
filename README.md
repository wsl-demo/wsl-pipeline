# WSL pipeline

A small, local analytics pipeline over Women's Super League match data. It's a
learning project: a free, laptop-sized version of the orchestrated
ingestion-and-transformation setup used on a production data team.

```text
  CSV files            Dagster ingestion         dbt models, run by Dagster
  (outside this repo)  ──►  raw schema      ──►  staging ─► intermediate ─► marts
  BBC Sport                 (DuckDB)
```

## 1. Source data

Match data from BBC Sport arrives as CSV files that live outside this
repository: matches, teams, players, cards, officials, pitch layouts, in-match
actions and player and team statistics. This repo never fetches them; it only
reads from the directory you point it at (`WSL_RAW_DIR` in `.env`).

## 2. Ingestion

Dagster loads each CSV into a `raw` schema in a local DuckDB database, one
asset per table and with every column kept as text. Nothing is cleaned here:
raw is the data exactly as it arrived. Each raw table is also declared as a dbt
source, which is what links ingestion to the models in Dagster's lineage graph.

## 3. Transformation

dbt builds the models in three layers, and Dagster materializes them as assets
downstream of ingestion:

| Layer | What it holds |
| --- | --- |
| Staging | One model per raw table, with names and types cleaned up. |
| Intermediate | Joins and derived logic, such as match points and each player's appearance history. |
| Marts | The entities you'd actually query, such as `dim_players` and `fct_player_appearances`. |

dbt tests run with the models, and Dagster surfaces them as asset checks.

## Getting started

```bash
cp .env.example .env   # then point WSL_RAW_DIR at the CSV directory
uv sync
just setup             # ingest everything and build every model
just dagster           # explore lineage and runs at http://localhost:3000
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for the day-to-day development workflow.
