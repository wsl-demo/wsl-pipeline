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

## ID convention: URN prefixes

BBC identifies players, teams and so on with URNs such as
`urn:bbc:sportsdata:football:player:s-a1b2c3d4e5f6a7b8c9d0e1f2g`. The prefix is
constant per entity type, so it only hurts readability.

- **Raw keeps full URNs**, exactly as received.
- **Staging strips the prefix** with the `strip_urn` macro, and names the column
  `*_id` (`player_id`, `team_id`, `venue_id`) because it is no longer a URN.
- **Everything downstream uses the short ids**, so never join a staged id to a raw URN.

```sql
{{ analytics.strip_urn('"playerUrn"', 'player') }} AS player_id
```

The `kind` is `player`, `team`, `event` (a match), `tournament`, `venue` or
`official`.

**A match is identified by its URN, not by BBC's page slug.** `match_id` is the
match URN without its prefix (`s-a1b2c3d4e5f6a7b8c9d0e1f2g`). The page slug in
raw `source_match_id` exists only once a match has been played, so it can't key
a table that also holds scheduled fixtures; staging builds `match_id` from
`urn` / `match_urn` instead, and a fixture keeps the same ID when it becomes a
result.

Teams have a second ID: BBC calls Opta's team ID the "participant ID", and
fixtures name teams by it rather than by URN. Staging exposes it as
`opta_team_id` (on matches, match teams and fixtures).

The macro only shortens values that start with the exact prefix and passes
anything else through untouched. `tests/staged_ids_have_no_urn_prefix.sql` then
fails on it, so mixed formats can't reach the marts. When you stage a new
URN column, add it to that test.

## Joining the two sources: Opta IDs

BBC Sport and wsl_football (the league's site) share Opta's IDs, which is how
they are joined, with no mapping table. Opta's IDs are also the keys in the
marts and the intermediate layer; BBC's own IDs stay in staging, as the source's
identity.

| Entity | In staging (BBC) | Everywhere downstream |
| --- | --- | --- |
| Player | `player_id` (`s-` + Opta ID), plus `opta_player_id` | `opta_player_id` |
| Team | `team_id` (URN slug such as `arsenal-ladies`); `opta_team_id` on `matches`, `match_teams` and fixtures | `opta_team_id` |

- **Players:** staging derives `opta_player_id` by dropping BBC's `s-`
  (the `opta_id_from_bbc_id` macro). `player_ids_are_s_prefixed` fails if any
  player ID ever lacks the prefix.
- **Teams:** BBC calls the Opta team ID its "participant ID". Only matches,
  match teams and fixtures carry it; the lineup, action and statistics tables
  have just the URN slug, so `int_players_joined_to_matches` looks the Opta ID up
  from the match's team list.

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
