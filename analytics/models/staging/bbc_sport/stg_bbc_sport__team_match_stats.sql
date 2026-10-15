-- Kept in the source's long shape: one row per team per match per statistic.
SELECT
    {{ analytics.strip_urn('"match_urn"', 'event') }} AS match_id,
    {{ analytics.strip_urn('"team_urn"', 'team') }} AS team_id,
    "alignment" AS alignment,
    "stat_path" AS stat_name,
    "stat_measure" AS stat_measure,
    CAST("stat_value" AS double) AS stat_value
FROM {{ source('bbc_sport', 'team_match_stats') }}
