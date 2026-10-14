SELECT
    "source_match_id" AS match_id,
    "source_side" AS source_side,
    {{ analytics.strip_urn('"urn"', 'team') }} AS team_id,
    "name_fullName" AS team_name,
    "name_shortName" AS team_short_name,
    "name_code" AS team_code,
    "alignment" AS alignment,
    "formation_value" AS formation,
    "manager_name_full" AS manager_name
FROM {{ source('bbc_sport', 'match_teams') }}
