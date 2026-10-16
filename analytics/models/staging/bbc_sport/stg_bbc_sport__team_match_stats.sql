-- Kept in the source's long shape: one row per team per match per statistic.
WITH parsed AS (
    SELECT
        {{ analytics.strip_urn('"match_urn"', 'event') }} AS bbc_match_id,
        {{ analytics.strip_urn('"team_urn"', 'team') }} AS bbc_team_id,
        "alignment" AS alignment,
        "stat_path" AS stat_name,
        "stat_measure" AS stat_measure,
        CAST("stat_value" AS double) AS stat_value
    FROM {{ source('bbc_sport', 'team_match_stats') }}
)
SELECT
    bbc_match_id,
    {{ analytics.opta_id_from_bbc_id('bbc_match_id') }} AS opta_match_id,
    bbc_team_id,
    alignment,
    stat_name,
    stat_measure,
    stat_value
FROM parsed
