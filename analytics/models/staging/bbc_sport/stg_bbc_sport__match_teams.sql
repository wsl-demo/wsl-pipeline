WITH parsed AS (
    SELECT
        {{ analytics.strip_urn('"match_urn"', 'event') }} AS bbc_match_id,
        "source_side" AS source_side,
        -- BBC's team slug (`arsenal-ladies`), the only team ID most BBC tables
        -- carry.
        {{ analytics.strip_urn('"urn"', 'team') }} AS bbc_team_id,
        -- Opta's team ID, which BBC calls the participant ID and sends as its
        -- own column. Listings use it in place of the URN.
        "id" AS opta_team_id,
        "name_fullName" AS team_name,
        "name_shortName" AS team_short_name,
        "name_code" AS team_code,
        "alignment" AS alignment,
        "formation_value" AS formation,
        "manager_id" AS bbc_manager_id,
        "manager_name_full" AS manager_name
    FROM {{ source('bbc_sport', 'match_teams') }}
)
SELECT
    bbc_match_id,
    {{ analytics.opta_id_from_bbc_id('bbc_match_id') }} AS opta_match_id,
    source_side,
    bbc_team_id,
    opta_team_id,
    team_name,
    team_short_name,
    team_code,
    alignment,
    formation,
    bbc_manager_id,
    manager_name
FROM parsed
