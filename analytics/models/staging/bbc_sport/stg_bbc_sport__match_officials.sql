SELECT
    {{ analytics.strip_urn('"match_urn"', 'event') }} AS match_id,
    {{ analytics.strip_urn('"id"', 'official') }} AS official_id,
    "firstName" AS first_name,
    "lastName" AS last_name
FROM {{ source('bbc_sport', 'match_officials') }}
