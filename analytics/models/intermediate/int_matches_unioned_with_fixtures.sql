-- One row per match, played or scheduled, with everything that follows from
-- the match itself: its season, whether it has been played, and the league
-- points each side earned.
--
-- A fixture and its result share an opta_match_id, so a match moves from
-- 'scheduled' to 'played' without changing identity. Where both exist the
-- result wins. Fixtures name teams by Opta ID, as results do, so both kinds of
-- row share a team key.
--
-- Season comes from the `season_of` macro on the match's UK date. Other models
-- call the same macro; none of them depend on this one for it.
WITH played AS (
    SELECT
        opta_match_id,
        'played' AS match_status,
        {{ uk_local_date('kicked_off_at') }} AS match_date,
        kicked_off_at,
        opta_home_team_id,
        opta_away_team_id,
        home_score_fulltime,
        away_score_fulltime,
        winner_side,
        tournament_name,
        venue_name
    FROM {{ ref('stg_bbc_sport__matches') }}
),

scheduled AS (
    SELECT
        opta_match_id,
        'scheduled' AS match_status,
        match_date,
        kicked_off_at,
        opta_home_team_id,
        opta_away_team_id,
        CAST(NULL AS integer) AS home_score_fulltime,
        CAST(NULL AS integer) AS away_score_fulltime,
        CAST(NULL AS varchar) AS winner_side,
        CAST(NULL AS varchar) AS tournament_name,
        CAST(NULL AS varchar) AS venue_name
    FROM {{ ref('stg_bbc_sport__fixtures') }}
    WHERE opta_match_id NOT IN (SELECT opta_match_id FROM played)
),

unioned AS (
    SELECT * FROM played
    UNION ALL
    SELECT * FROM scheduled
)

SELECT
    opta_match_id,
    opta_home_team_id,
    opta_away_team_id,
    match_status,
    {{ season_of('match_date') }} AS season,
    winner_side,
    tournament_name,
    venue_name,
    home_score_fulltime,
    away_score_fulltime,
    -- League points: 3 for a win, 1 for a draw, 0 for a loss. A football
    -- scoring rule rather than a cleanup of the source, so it lives here.
    CASE winner_side
        WHEN 'home' THEN 3
        WHEN 'away' THEN 0
        WHEN 'draw' THEN 1
    END AS home_points,
    CASE winner_side
        WHEN 'home' THEN 0
        WHEN 'away' THEN 3
        WHEN 'draw' THEN 1
    END AS away_points,
    match_date,
    kicked_off_at
FROM unioned
