-- Kept in the source's long shape: one row per player per match per statistic.
-- Reshaping to one row per appearance is the intermediate layer's job, in
-- int_player_match_stats__pivoted.
WITH parsed AS (
    SELECT
        {{ analytics.strip_urn('"match_urn"', 'event') }} AS bbc_match_id,
        {{ analytics.strip_urn('"team_urn"', 'team') }} AS bbc_team_id,
        {{ analytics.strip_urn('"playerUrn"', 'player') }} AS bbc_player_id,
        CAST("stat_index" AS integer) AS stat_index,
        "dataField" AS stat_name,
        "rowLabel" AS stat_label,
        CAST("statValue" AS double) AS stat_value
    FROM {{ source('bbc_sport', 'player_match_stats') }}
)
SELECT
    bbc_match_id,
    {{ analytics.opta_id_from_bbc_id('bbc_match_id') }} AS opta_match_id,
    bbc_team_id,
    bbc_player_id,
    {{ analytics.opta_id_from_bbc_id('bbc_player_id') }} AS opta_player_id,
    stat_index,
    stat_name,
    stat_label,
    stat_value
FROM parsed
