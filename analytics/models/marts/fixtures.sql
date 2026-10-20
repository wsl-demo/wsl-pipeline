-- One row per fixture: every match BBC has listed, in whatever state BBC lists
-- it now, with its season, its result once it has one, and the league points
-- each side earned.
--
-- The state is BBC's, from the match's latest observation in the listings
-- (`int_matches_listing_state_derived`), and says as of when (`last_listed_at`):
--
-- - `scheduled`: still to come, at the date and kickoff BBC lists;
-- - `in_play`: being played when last listed;
-- - `finished`: BBC lists a result;
-- - `no_longer_listed`: a later fetch covered its date and did not list it, so
--   the date and kickoff are the last ones BBC listed. No reason is claimed.
--
-- A status BBC has never sent before leaves `state` null and fails its test,
-- rather than being mapped to a guess.
--
-- Result columns are filled only when finished. While a match is in play BBC's
-- score is a running score and its winner the side leading, and neither is a
-- result. An awarded match is finished with BBC's winner and no score to speak
-- of (it is listed 0-0), so points follow `winner_side`, never the score.
--
-- The venue and the managers come from the match's own page, which exists only
-- from the 2023-24 season and only once a match has finished. The marts start
-- at that season (`first_season` in dbt_project.yml); the listings go back to
-- 2020-21.
--
-- Season comes from the `season_of` macro on the match's UK date. Other models
-- call the same macro; none of them depend on this one for it. The matchday is
-- derived in `int_fixtures_matchday_derived` and is null for a match that
-- cannot be placed without guessing.
WITH listed AS (
    SELECT
        *,
        CASE
            WHEN no_longer_listed_at IS NOT NULL THEN 'no_longer_listed'
            WHEN bbc_status = 'PreEvent' THEN 'scheduled'
            WHEN bbc_status = 'MidEvent' THEN 'in_play'
            WHEN bbc_status = 'PostEvent' THEN 'finished'
        END AS state,
        {{ season_of('match_date') }} AS season
    FROM {{ ref('int_matches_listing_state_derived') }}
),

pages AS (
    SELECT
        opta_match_id,
        venue_name
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

kickoff_changes AS (
    SELECT
        opta_match_id,
        MAX(changed_at) AS kickoff_changed_at
    FROM {{ ref('int_matches_kickoff_changes_derived') }}
    GROUP BY opta_match_id
),

results AS (
    SELECT
        opta_match_id,
        state,
        state = 'finished' AS has_result,
        CASE WHEN state = 'finished' THEN winner_side END AS winner_side,
        CASE WHEN state = 'finished' THEN home_score_fulltime END AS home_score_fulltime,
        CASE WHEN state = 'finished' THEN away_score_fulltime END AS away_score_fulltime,
        state = 'finished' AND bbc_status_note LIKE 'Match awarded to %' AS is_awarded
    FROM listed
)

SELECT
    listed.opta_match_id,
    listed.opta_home_team_id,
    listed.opta_away_team_id,
    results.state,
    results.has_result,
    listed.season,
    matchdays.matchday,
    results.winner_side,
    results.is_awarded,
    listed.bbc_status,
    listed.bbc_status_note,
    listed.tournament_name,
    pages.venue_name,
    home_teams.bbc_manager_id AS bbc_home_manager_id,
    away_teams.bbc_manager_id AS bbc_away_manager_id,
    results.home_score_fulltime,
    results.away_score_fulltime,
    -- League points: 3 for a win, 1 for a draw, 0 for a loss. A football
    -- scoring rule rather than a cleanup of the source.
    CASE results.winner_side
        WHEN 'home' THEN 3
        WHEN 'away' THEN 0
        WHEN 'draw' THEN 1
    END AS home_points,
    CASE results.winner_side
        WHEN 'home' THEN 0
        WHEN 'away' THEN 3
        WHEN 'draw' THEN 1
    END AS away_points,
    listed.match_date,
    listed.kicked_off_at,
    listed.is_kickoff_time_tbc,
    kickoff_changes.kickoff_changed_at,
    listed.first_listed_at,
    listed.last_listed_at,
    listed.no_longer_listed_at
FROM listed
INNER JOIN results
    ON listed.opta_match_id = results.opta_match_id
LEFT JOIN pages
    ON listed.opta_match_id = pages.opta_match_id
LEFT JOIN home_teams
    ON listed.opta_match_id = home_teams.opta_match_id
LEFT JOIN away_teams
    ON listed.opta_match_id = away_teams.opta_match_id
LEFT JOIN kickoff_changes
    ON listed.opta_match_id = kickoff_changes.opta_match_id
LEFT JOIN {{ ref('int_fixtures_matchday_derived') }} AS matchdays
    ON listed.opta_match_id = matchdays.opta_match_id
WHERE listed.season >= '{{ var("first_season") }}'
