-- One row per fixture: every match BBC has listed, on its fixtures pages, its
-- results, or both, with its season and the league points each side earned.
--
-- The fixtures pages say only that a match was still to come when the page was
-- fetched, and past months' pages are not fetched again. So a fixture without a
-- result is not known to be in the future: it may have been played since, or
-- postponed. This model makes no claim either way; it records whether a result
-- exists (`has_result`) and leaves the result columns null when none does.
--
-- A fixture and its result share an opta_match_id, so they are full-outer
-- joined on it. Where both carry a value the result's wins: it records what
-- happened, the fixture what was planned. Both name teams by Opta ID, and
-- `fixtures_agree_with_results` checks that they name the same ones.
--
-- Managers come from `stg_bbc_sport__match_teams`, which exists only for played
-- matches, so their IDs are null for a fixture without a result. Names are in
-- `managers`.
--
-- Season comes from the `season_of` macro on the match's UK date. Other models
-- call the same macro; none of them depend on this one for it.
--
-- The matchday is derived in `int_fixtures_matchday_derived` and is null for a
-- match that cannot be placed without guessing.
WITH fixtures AS (
    SELECT
        opta_match_id,
        opta_home_team_id,
        opta_away_team_id,
        tournament_name,
        match_date,
        kicked_off_at
    FROM {{ ref('stg_bbc_sport__fixtures') }}
),

results AS (
    SELECT
        opta_match_id,
        opta_home_team_id,
        opta_away_team_id,
        tournament_name,
        {{ uk_local_date('kicked_off_at') }} AS match_date,
        kicked_off_at,
        venue_name,
        home_score_fulltime,
        away_score_fulltime,
        winner_side
    FROM {{ ref('stg_bbc_sport__matches') }}
),

home_teams AS (
    SELECT
        opta_match_id,
        bbc_manager_id
    FROM {{ ref('stg_bbc_sport__match_teams') }}
    WHERE source_side = 'homeTeam'
),

away_teams AS (
    SELECT
        opta_match_id,
        bbc_manager_id
    FROM {{ ref('stg_bbc_sport__match_teams') }}
    WHERE source_side = 'awayTeam'
),

joined AS (
    SELECT
        COALESCE(results.opta_match_id, fixtures.opta_match_id) AS opta_match_id,
        COALESCE(results.opta_home_team_id, fixtures.opta_home_team_id) AS opta_home_team_id,
        COALESCE(results.opta_away_team_id, fixtures.opta_away_team_id) AS opta_away_team_id,
        results.opta_match_id IS NOT NULL AS has_result,
        COALESCE(results.tournament_name, fixtures.tournament_name) AS tournament_name,
        -- Only results carry these.
        results.venue_name,
        results.home_score_fulltime,
        results.away_score_fulltime,
        results.winner_side,
        -- A postponed match keeps its ID, so its fixture row can hold a date
        -- it was never played on; the result's date is the one it happened.
        COALESCE(results.match_date, fixtures.match_date) AS match_date,
        COALESCE(results.kicked_off_at, fixtures.kicked_off_at) AS kicked_off_at
    FROM fixtures
    FULL OUTER JOIN results
        ON fixtures.opta_match_id = results.opta_match_id
)

SELECT
    joined.opta_match_id,
    joined.opta_home_team_id,
    joined.opta_away_team_id,
    joined.has_result,
    {{ season_of('joined.match_date') }} AS season,
    matchdays.matchday,
    joined.winner_side,
    joined.tournament_name,
    joined.venue_name,
    home_teams.bbc_manager_id AS bbc_home_manager_id,
    away_teams.bbc_manager_id AS bbc_away_manager_id,
    joined.home_score_fulltime,
    joined.away_score_fulltime,
    -- League points: 3 for a win, 1 for a draw, 0 for a loss. A football
    -- scoring rule rather than a cleanup of the source.
    CASE joined.winner_side
        WHEN 'home' THEN 3
        WHEN 'away' THEN 0
        WHEN 'draw' THEN 1
    END AS home_points,
    CASE joined.winner_side
        WHEN 'home' THEN 0
        WHEN 'away' THEN 3
        WHEN 'draw' THEN 1
    END AS away_points,
    joined.match_date,
    joined.kicked_off_at
FROM joined
LEFT JOIN home_teams
    ON joined.opta_match_id = home_teams.opta_match_id
LEFT JOIN away_teams
    ON joined.opta_match_id = away_teams.opta_match_id
LEFT JOIN {{ ref('int_fixtures_matchday_derived') }} AS matchdays
    ON joined.opta_match_id = matchdays.opta_match_id
