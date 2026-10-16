# Contributing

Raw CSVs are ingested by Dagster into DuckDB's `raw` schema, then dbt turns
them into staging, intermediate and mart models. Run `just` to list commands.

## Setup

1. Install [uv](https://docs.astral.sh/uv/) and [just](https://just.systems/), then run `uv sync`.
2. Copy `.env.example` to `.env` and set:
   - `WSL_RAW_DIR`: directory holding the source data CSV files (absolute, or relative to the repo root).
   - `DATABASE_NAME`: DuckDB file created in `analytics/`.
   - `PUBLISH_PG_*`: where `just publish` sends the finished tables. Only needed to publish; see [Publishing to the app](#publishing-to-the-app).
3. Run `just setup` to ingest the CSVs and build every model.

## Building a model

1. **Ingest the data.** For a new raw table, add its name under its source in
   `SOURCES` in `orchestration/ingestion.py` (a new source gets a new key), then
   declare it under `sources` in that source's
   `analytics/models/staging/<source>/_<source>__sources.yml`. All sources share
   the `raw` schema, so table names must be unique across them.

   Declare every raw column a model or test uses, with `data_type: varchar`
   and a description of what the source sends. dbt reads source schemas from
   these declarations (`schema_origin: local` in `dbt_project.yml`) rather
   than from the warehouse, which is what gives the docs CI column lineage
   without the data. A column used but not declared fails strict compilation
   with `No column … found`; a column nothing uses isn't declared.
2. **Write the model** in the layer it belongs to:

   | Layer | Folder | Job |
   | --- | --- | --- |
   | Staging | `models/staging/` | One model per raw table: rename, cast, parse. No business rules. |
   | Intermediate | `models/intermediate/` | Joins, reshaping and derived logic. |
   | Marts | `models/marts/` | Business-facing entities. |

   Reference raw tables with `source()` and everything else with `ref()`.
   Raw columns are all `varchar`, so staging is where types are set.
3. **Document and test it** in the YAML beside the model: a description, plus
   `unique` / `not_null` on keys and `accepted_values` on categories. Logic that
   is easy to get subtly wrong (clocks, boundaries, parsing) also gets a unit
   test: see [Unit tests](#unit-tests).
4. **Build it:** `just build --select my_model+` builds the model and its downstream models, with tests.
5. **Inspect it:** `just show my_model` previews rows.
6. **Debug failures:** `just failures` prints the rows behind failed tests
   from the latest run. Tests that errored (rather than failed) show in the dbt output.

## ID convention: `bbc_*_id` and `opta_*_id`

Every staged identifier says whose it is:

- **`opta_*_id`**: confirmed to be Opta's ID. These are the keys downstream.
- **`bbc_*_id`**: BBC's own ID, or an ID BBC sends that is not confirmed as
  Opta's (venue, official, manager). These stay in staging.

| Entity | `bbc_*_id` (staging only) | `opta_*_id` (downstream key) |
| --- | --- | --- |
| Match | `bbc_match_id`: `s-` + Opta ID | `opta_match_id` |
| Player | `bbc_player_id`: `s-` + Opta ID | `opta_player_id` |
| Team | `bbc_team_id`: slug such as `arsenal-ladies` | `opta_team_id`: what BBC calls the participant ID |
| Tournament | `bbc_tournament_id`: slug `womens-super-league` | `opta_tournament_id` |
| Stage | — | `opta_stage_id`: one "Regular Season" per season |
| Venue | `bbc_venue_id`: `s-` + an unconfirmed ID | — |
| Official | `bbc_official_id`, `bbc_official_op_id` | — |
| Manager | `bbc_manager_id` | — |

Home and away versions put the owner first: `bbc_home_team_id`,
`opta_home_team_id`.

**How the Opta IDs were confirmed** (October 2026): match IDs against 21
matches in an Opta fixtures feed, team IDs against all 14 clubs in an Opta
standings feed (and wsl_football's `team_optaId`), tournament and stage IDs
against the same feeds, and player IDs through the join to wsl_football. Venue,
official and manager IDs look like Opta's but have not been checked, so they
keep BBC names until they are.

### Getting from raw to staging

BBC often sends an ID as a URN such as
`urn:bbc:sportsdata:football:player:s-a1b2c3d4e5f6a7b8c9d0e1f2g`.

- **Raw keeps values exactly as received.**
- **Strip a URN only when it is the sole BBC ID for that entity.** The
  `strip_urn` macro drops the constant prefix. A field that already holds the
  short form, like fixtures' `event_id`, is staged as sent. Where BBC sends
  Opta's ID as a bare column (`home_id`, `tournament_id`, `stage_id`), that
  column becomes the `opta_*_id` as is.
- **Derive an Opta ID from an `s-` BBC ID** with `opta_id_from_bbc_id`, which
  drops the `s-` and returns null for anything else.

Each staging model reads the source in a `parsed` CTE, which builds every
`bbc_*_id` and renames any column BBC already sends as an Opta ID. The final
`SELECT` derives the remaining Opta IDs from their BBC IDs, so the two ways an
Opta ID arrives stay visible:

```sql
WITH parsed AS (
    SELECT
        {{ analytics.strip_urn('"urn"', 'player') }} AS bbc_player_id,
        "home_id" AS opta_home_team_id,  -- sent by BBC as its own column
        ...
)
SELECT
    bbc_player_id,
    {{ analytics.opta_id_from_bbc_id('bbc_player_id') }} AS opta_player_id,  -- derived
    opta_home_team_id,
    ...
FROM parsed
```

The `kind` is `player`, `team`, `event` (a match), `tournament`, `venue` or
`official`.

Two tests guard the derivation. `staged_ids_have_no_urn_prefix` fails if a URN
with an unknown prefix slips through `strip_urn`, and `bbc_ids_are_s_prefixed`
fails if an ID that an Opta ID is derived from lacks its `s-`. When you stage a
new column of either kind, add it to the matching test.

BBC's match page slug (`source_match_id`) is staged unchanged on
`stg_bbc_sport__matches` as `bbc_match_page_id`, for tracing a row to its
page. It exists only once a match is played, so it can't key a table that also
holds fixtures, and nothing downstream uses it.

## Joining the two sources: Opta IDs

BBC Sport and wsl_football (the league's site) share Opta's IDs, which is how
they are joined, with no mapping table. Opta's IDs are also the keys in the
marts and the intermediate layer.

Most BBC tables carry only BBC's team slug, not the Opta team ID. Only
matches, match teams and fixtures have `opta_team_id`, so
`int_players_joined_to_matches` looks it up from the match's team list on
`bbc_team_id`.

wsl_football is used for **biographical data only** (nationality, date of birth,
height, weight, and the names of players BBC hasn't listed yet). Which team a
player is on always comes from BBC Sport. `players` therefore holds every player
from either source, keyed on `opta_player_id`, and a player appears in
`squad_members` only once BBC has named them in a matchday squad.

## Seasons

A season runs from 1 July to 30 June and is written `2026-2027`. The rule lives
in one place, the `season_of` macro (with `uk_local_date`, because a late-June
kickoff in UTC can already be July in London). Models that need a season call it
on a date they already have; none of them inherit it from another model, which
keeps `int_matches_unioned_with_fixtures` feeding only `matches`.
`matchday_season_matches_match_season` fails if two call sites ever disagree.

## The marts

Marts are named for the concept at their grain, not with `fct_` / `dim_`
prefixes.

| Mart | One row per | Notes |
| --- | --- | --- |
| `matches` | match | Played and scheduled, with `season`, status and points. |
| `matchday_squad_members` | player per match | Starters and the whole bench. Count appearances with `has_appeared`, not with rows. |
| `squad_members` | player per team per season | Inferred from matchday squads, with biography joined in. A player is absent if never named in a squad. |
| `players` | player | Names and biography only. |
| `teams` | team | Includes clubs no longer in the league. |
| `seasons` | season | `is_current` is the latest season present. |

Column conventions follow dbt's style guide: booleans start `is_` / `has_`,
timestamps end `_at`, dates end `_date`, and keys are strings.

## Marts are a contract

Everything in `models/marts/` is published to the app, so each mart declares
`contract: {enforced: true}` and a `data_type` for every column. The build fails
if a model stops matching its YAML, which is how a rename or retype shows up
here as a red build instead of in the app as a broken page. When you add or
change a mart column, update the YAML in the same commit.

Adding a mart to the app is one more step: add its name to `TABLES` in
`orchestration/publish.py`. Renaming or removing one leaves the old table in
`analytics` until you drop it by hand.

## Unit tests

`models/staging/bbc_sport/_bbc_sport__unit_tests.yml` holds small fixed inputs
for the logic where an off-by-one hides: match clock and period boundaries,
substitution minutes, URN prefixes, fixture dates and daylight saving. Real data
only covers the cases it happens to contain; these pin the edges.

```bash
just dbt test --select test_type:unit
```

They also run as part of `just build`. Dagster's run skips them, because
`dagster-dbt` can't handle unit-test events; they check the SQL, not the data, so
`just build` is where they belong.

## Publishing to the app

`just publish` runs the whole graph (ingest, build, test) and then copies the
marts into the app's Postgres. Dagster skips the publish step when any dbt test
fails, so a red build never reaches the app; this is why there is no
publish-only command.

- **Where:** the `analytics` schema of the app's database. The pipeline connects
  as `pipeline_writer`, which can create and replace tables in `analytics` and
  `analytics_next` and touch nothing in `public`. The app's `api_reader` can
  only `SELECT`.
- **How:** each table is loaded into `analytics_next`, then all of them move into
  `analytics` in one batch, so a reader sees the whole old set or the whole new
  set, never a mix.
- **Credentials:** `PUBLISH_PG_DB`, `PUBLISH_PG_USER` and `PUBLISH_PG_PASSWORD`
  in `.env` (`PUBLISH_PG_HOST` and `PUBLISH_PG_PORT` default to
  `localhost:5432`). The role is created by the app repo's `deploy/db-init/`.
- **Not cleaned up:** a mart you rename or remove stays in `analytics` until you
  drop it by hand.

Don't put foreign keys from app tables onto these tables: publishing replaces a
table by dropping it.

## Before pushing a commit

- `just build` passes with no failures, and `just failures` reports none.
- `just docs` renders the lineage you expect.
- Change dbt YAML or SQL, then run `just setup` (not only Dagster) so
  Dagster's manifest is refreshed.
- CI (`.github/workflows/ci.yml`) runs `ruff`, `dbt parse` and a strict compile
  without the raw data. Run the same locally with `uv run ruff check . &&
  uv run ruff format --check .` and `just dbt compile --static-analysis strict`.
  Prefer standard SQL (`AT TIME ZONE`, not DuckDB's `timezone()`): the strict
  analyzer rejects functions it doesn't know, and `just docs` depends on it.

## Useful commands

| Command | Purpose |
| --- | --- |
| `just setup` | Ingest raw data and build all models; creates the warehouse. Publishes nothing. |
| `just publish` | `setup`, then copy the finished marts into the app's Postgres. |
| `just dagster` | Dagster UI at <http://localhost:3000> for runs, lineage and asset checks. |
| `just build [args]` | `dbt build`, e.g. `--select stg_bbc_sport__matches+`. |
| `just failures` | Show rows behind failing tests. |
| `just docs` | Generate and serve the dbt docs site. |
| `just dbeaver` | Open the warehouse in DBeaver. |
| `just dbt <cmd>` | Run any other dbt command. |

DuckDB allows one writer at a time, so **disconnect in DBeaver before running
`just setup`, `just build` or Dagster**, or they fail with `Could not set lock on file`.

To start over, delete `analytics/$DATABASE_NAME` and run `just setup`.
