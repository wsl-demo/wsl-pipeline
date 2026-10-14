SELECT
    "source_match_id" AS match_id,
    "source_side" AS source_side,
    {{ analytics.strip_urn('"team_urn"', 'team') }} AS team_id,
    {{ analytics.strip_urn('"urn"', 'player') }} AS player_id,
    CAST("row_index" AS integer) AS row_index,
    CAST("slot_index" AS integer) AS slot_index
FROM {{ source('bbc_sport', 'match_pitch_layout') }}
