-- Reshapes the long player statistics into one row per appearance.
--
-- The statistic list is enumerated here, which is safe because
-- stg_bbc_sport__player_match_stats tests `stat_name` against exactly these
-- values: a new or renamed statistic fails that test rather than silently
-- going missing from this pivot.
--
-- The source is sparse, so these measures are legitimately nullable. Only
-- goalkeepers record `shotsSaved`, and `minsPlayed` is absent for some
-- appearances.
SELECT
    match_id,
    player_id,
    team_id,
    MAX(CASE WHEN stat_name = 'minsPlayed' THEN stat_value END) AS minutes_played,
    MAX(CASE WHEN stat_name = 'goals' THEN stat_value END) AS goals,
    MAX(CASE WHEN stat_name = 'assists' THEN stat_value END) AS assists,
    MAX(CASE WHEN stat_name = 'totalAssists' THEN stat_value END) AS chances_created,
    MAX(CASE WHEN stat_name = 'shotsTotal' THEN stat_value END) AS shots_total,
    MAX(CASE WHEN stat_name = 'shotsOnTarget' THEN stat_value END) AS shots_on_target,
    MAX(CASE WHEN stat_name = 'shotsSaved' THEN stat_value END) AS saves,
    MAX(CASE WHEN stat_name = 'totalPass' THEN stat_value END) AS total_passes,
    MAX(CASE WHEN stat_name = 'accuratePassPercentage' THEN stat_value END) AS pass_accuracy_pct,
    MAX(CASE WHEN stat_name = 'totalTackle' THEN stat_value END) AS total_tackles,
    MAX(CASE WHEN stat_name = 'wonTacklePercentage' THEN stat_value END) AS tackles_won_pct,
    MAX(CASE WHEN stat_name = 'fouls' THEN stat_value END) AS fouls_committed,
    MAX(CASE WHEN stat_name = 'wasFouled' THEN stat_value END) AS fouls_won
FROM {{ ref('stg_bbc_sport__player_match_stats') }}
GROUP BY match_id, player_id, team_id
