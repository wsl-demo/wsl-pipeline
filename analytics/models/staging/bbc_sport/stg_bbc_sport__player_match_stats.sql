-- Kept in the source's long shape: one row per player per match per statistic.
-- Reshaping to one row per appearance is the intermediate layer's job, in
-- int_player_match_stats__pivoted.
SELECT
    "source_match_id" AS match_id,
    {{ analytics.strip_urn('"team_urn"', 'team') }} AS team_id,
    {{ analytics.strip_urn('"playerUrn"', 'player') }} AS player_id,
    CAST("stat_index" AS integer) AS stat_index,
    "dataField" AS stat_name,
    "rowLabel" AS stat_label,
    CAST("statValue" AS double) AS stat_value
FROM {{ source('bbc_sport', 'player_match_stats') }}
