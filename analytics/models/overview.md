{% docs __overview__ %}
# WSL pipeline

Women's Super League data, from two data sources, turned into seven tested
tables that a web app serves. This site documents every step in between. The
lineage graph shows how the models connect; this page explains what the data
means and why each layer exists.

## The two sources

| Source | What it holds | Used for |
| --- | --- | --- |
| `bbc_sport` | BBC Sport's page for every played match (score, squads, goals, cards, statistics) and its fixtures pages listing matches to come | Everything about matches and who played in them |
| `wsl_football` | The league's own site: the players in each club's current squad | Player biography only: nationality, birth date, height, weight |

Both are written to CSV and loaded into the `raw` schema as text. Which team a
player was in always comes from BBC Sport. `wsl_football` is a snapshot of
current squads, so it knows nothing about players who have since left.

## One set of IDs

Both sources identify matches and players with the IDs of **Opta**, a sports
data provider. BBC writes them with an `s-` in front, so BBC's player
`s-9t8eb24gwj56ucggp7x0n0ewa` is Opta's player `9t8eb24gwj56ucggp7x0n0ewa`.
Teams are the exception: BBC's own team ID is a slug such as `arsenal-ladies`,
and Opta's team ID appears only on the tables that list teams by side
(`matches`, `match_teams`, `fixtures`).

Column names say whose ID a column holds: `bbc_*_id` for BBC's form, `opta_*_id`
for Opta's. Staging carries both; every model after staging joins on
`opta_*_id` only.

## The layers

| Layer | Built as | What it does |
| --- | --- | --- |
| **Staging** (`stg_<source>__<table>`) | Views | One model per raw table, and no joins. Each renames columns, casts text to proper types, removes BBC's URN prefixes, derives Opta IDs, and turns coded text into flags. Each staging model's description lists its grain, what it changes and which raw columns it leaves behind. |
| **Intermediate** (`int_*`) | Views | Joins and reshapes: fixtures joined to their results, squads joined to their matches, statistics pivoted from one row per statistic to one row per appearance, starts counted by position, assists matched to players by name, every timed action stacked into one shape, each player's time on the pitch derived. Not published. |
| **Marts** | Tables, with enforced contracts | The seven finished tables below. These are what the app receives. |

## The marts

| Mart | One row per |
| --- | --- |
| `fixtures` | Match, with its result where one exists |
| `match_performances` | Player per match they were named in the squad for, with their statistics and time on the pitch |
| `match_actions` | Goal, assist, card or substitution, per player involved |
| `squad_members` | Player per team per season |
| `players` | Player |
| `teams` | Team |
| `seasons` | Season |

`publish_marts`, a Dagster asset outside dbt, copies all seven into the app's
Postgres after every model builds and every test passes. The `wsl_app`
exposure records that dependency.

## Conventions that hold everywhere

- **Null means not recorded, not zero.** Where BBC shows a statistic it records
  zeros too, including for unused substitutes. Where it doesn't show one, the
  value is null: a starting goalkeeper has no goals, shots or chances created,
  and only goalkeepers have saves. Sums skip nulls, so a goalkeeper's goal total
  is null rather than zero.
- **A season runs from 1 July to 30 June** and is labelled like `2026-2027`. The
  `season_of` macro is the one definition of the rule. The current season is
  the latest one in the data, not the one containing today's date.
- **Dates are UK local.** Kickoffs are stored as absolute timestamps; a match's
  date is the day it was played in the UK.
- **Squads are inferred.** A player belongs to a team's squad in a season when
  named in one of its matchday squads that season. Nobody who never made a
  matchday squad appears in `squad_members`.
{% enddocs %}
