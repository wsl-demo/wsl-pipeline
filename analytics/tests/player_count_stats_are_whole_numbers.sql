-- int_player_match_stats_pivoted casts these statistics to integer, and a cast
-- rounds without complaint. A fractional value means the source changed what the
-- statistic holds, and should be seen here instead of being rounded away.
--
-- The two percentage statistics (accuratePassPercentage, wonTacklePercentage)
-- are legitimately fractional and are not listed.
SELECT
    opta_match_id,
    opta_player_id,
    stat_name,
    stat_value
FROM {{ ref('stg_bbc_sport__player_match_stats') }}
WHERE stat_name IN (
        'minsPlayed', 'goals', 'assists', 'totalAssists', 'shotsTotal',
        'shotsOnTarget', 'shotsSaved', 'totalPass', 'totalTackle', 'fouls',
        'wasFouled'
    )
    AND stat_value <> FLOOR(stat_value)
