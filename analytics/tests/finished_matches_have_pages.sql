-- Every match BBC lists as finished with a page should have that page
-- collected: the scraper fetches it in the same run that first sees the match
-- finished. A row here means a page fetch failed or the scraper has not run
-- since, so the match's details (venue, squads, statistics) are missing for
-- now. It warns rather than fails, because the result itself is still right.
{{ config(severity='warn') }}

SELECT
    listed.opta_match_id,
    listed.bbc_match_page_id,
    listed.last_listed_at
FROM {{ ref('int_matches_listing_state_derived') }} AS listed
LEFT JOIN {{ ref('stg_bbc_sport__match_pages') }} AS pages
    ON listed.bbc_match_page_id = pages.bbc_match_page_id
WHERE listed.bbc_status = 'PostEvent'
  AND listed.bbc_match_page_id IS NOT NULL
  AND pages.bbc_match_page_id IS NULL
