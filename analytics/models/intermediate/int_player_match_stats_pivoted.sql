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
--
-- Counts are cast to integer and the two percentages stay double. The source
-- stores every statistic as a decimal, and DuckDB rounds on a cast rather than
-- failing, so `player_count_stats_are_whole_numbers` guards the cast: a
-- fractional count fails there instead of being quietly altered here.
SELECT
    match_id,
    opta_player_id,
    CAST(MAX(CASE WHEN stat_name = 'minsPlayed' THEN stat_value END) AS integer) AS minutes_played,
    CAST(MAX(CASE WHEN stat_name = 'goals' THEN stat_value END) AS integer) AS goals,
    CAST(MAX(CASE WHEN stat_name = 'assists' THEN stat_value END) AS integer) AS assists,
    CAST(MAX(CASE WHEN stat_name = 'totalAssists' THEN stat_value END) AS integer) AS chances_created,
    CAST(MAX(CASE WHEN stat_name = 'shotsTotal' THEN stat_value END) AS integer) AS shots_total,
    CAST(MAX(CASE WHEN stat_name = 'shotsOnTarget' THEN stat_value END) AS integer) AS shots_on_target,
    CAST(MAX(CASE WHEN stat_name = 'shotsSaved' THEN stat_value END) AS integer) AS saves,
    CAST(MAX(CASE WHEN stat_name = 'totalPass' THEN stat_value END) AS integer) AS total_passes,
    MAX(CASE WHEN stat_name = 'accuratePassPercentage' THEN stat_value END) AS pass_accuracy_percent,
    CAST(MAX(CASE WHEN stat_name = 'totalTackle' THEN stat_value END) AS integer) AS total_tackles,
    MAX(CASE WHEN stat_name = 'wonTacklePercentage' THEN stat_value END) AS tackles_won_percent,
    CAST(MAX(CASE WHEN stat_name = 'fouls' THEN stat_value END) AS integer) AS fouls_committed,
    CAST(MAX(CASE WHEN stat_name = 'wasFouled' THEN stat_value END) AS integer) AS fouls_won
FROM {{ ref('stg_bbc_sport__player_match_stats') }}
GROUP BY match_id, opta_player_id
