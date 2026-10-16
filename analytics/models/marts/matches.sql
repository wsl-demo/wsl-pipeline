-- One row per match, played or scheduled, with its season and the league
-- points each side earned. The logic lives in int_matches_unioned_with_fixtures;
-- this is the published, contracted entity.
SELECT
    opta_match_id,
    opta_home_team_id,
    opta_away_team_id,
    match_status,
    season,
    winner_side,
    tournament_name,
    venue_name,
    home_score_fulltime,
    away_score_fulltime,
    home_points,
    away_points,
    match_date,
    kicked_off_at
FROM {{ ref('int_matches_unioned_with_fixtures') }}
