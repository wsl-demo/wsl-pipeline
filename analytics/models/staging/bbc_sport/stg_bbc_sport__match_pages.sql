-- BBC's match pages themselves, as of their latest stored version: editorial
-- pages about a match, only from the 2023-24 season. BBC can make one days
-- before kickoff, but a page is stored only once its match has finished. A page
-- has its own timeline: its coverage start and end are not the match's kickoff
-- and finish.
WITH parsed AS (
    SELECT
        "source_match_id" AS bbc_match_page_id,
        {{ analytics.strip_urn('"match_urn"', 'event') }} AS bbc_match_id,
        "title" AS page_title,
        CAST("startDateTime" AS timestamp with time zone) AS coverage_started_at,
        CAST("endDateTime" AS timestamp with time zone) AS coverage_ended_at,
        CAST("source_fetched_at" AS timestamp with time zone) AS fetched_at,
        CAST("source_first_fetched_at" AS timestamp with time zone) AS first_fetched_at,
        CAST("source_versions" AS integer) AS fetched_versions
    FROM {{ source('bbc_sport', 'match_pages') }}
)

SELECT
    bbc_match_page_id,
    bbc_match_id,
    {{ analytics.opta_id_from_bbc_id('bbc_match_id') }} AS opta_match_id,
    page_title,
    coverage_started_at,
    coverage_ended_at,
    fetched_at,
    first_fetched_at,
    fetched_versions
FROM parsed
