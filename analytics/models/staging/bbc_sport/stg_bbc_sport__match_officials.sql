WITH parsed AS (
    SELECT
        {{ analytics.strip_urn('"match_urn"', 'event') }} AS bbc_match_id,
        -- Unlike player and match URNs, the official URN's tail has no `s-`. It
        -- looks like an Opta ID but is unconfirmed, so it stays BBC-named.
        {{ analytics.strip_urn('"id"', 'official') }} AS bbc_official_id,
        -- A short numeric ID, present for only a handful of officials.
        "opId" AS bbc_official_op_id,
        "firstName" AS first_name,
        "lastName" AS last_name
    FROM {{ source('bbc_sport', 'match_officials') }}
)
SELECT
    bbc_match_id,
    {{ analytics.opta_id_from_bbc_id('bbc_match_id') }} AS opta_match_id,
    bbc_official_id,
    bbc_official_op_id,
    first_name,
    last_name
FROM parsed
