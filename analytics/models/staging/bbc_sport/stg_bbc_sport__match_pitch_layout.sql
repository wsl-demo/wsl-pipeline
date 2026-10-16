WITH parsed AS (
    SELECT
        {{ analytics.strip_urn('"match_urn"', 'event') }} AS bbc_match_id,
        "source_side" AS source_side,
        {{ analytics.strip_urn('"team_urn"', 'team') }} AS bbc_team_id,
        {{ analytics.strip_urn('"urn"', 'player') }} AS bbc_player_id,
        CAST("row_index" AS integer) AS row_index,
        CAST("slot_index" AS integer) AS slot_index
    FROM {{ source('bbc_sport', 'match_pitch_layout') }}
)
SELECT
    bbc_match_id,
    {{ analytics.opta_id_from_bbc_id('bbc_match_id') }} AS opta_match_id,
    source_side,
    bbc_team_id,
    bbc_player_id,
    {{ analytics.opta_id_from_bbc_id('bbc_player_id') }} AS opta_player_id,
    row_index,
    slot_index
FROM parsed
