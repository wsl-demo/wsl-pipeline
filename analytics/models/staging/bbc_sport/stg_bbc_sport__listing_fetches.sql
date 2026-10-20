-- Each fetch of a BBC listing page, with the window of days BBC applied. A
-- listing names every match BBC dates within its window, whatever its status,
-- so these windows are what make a match's absence mean something: a match
-- missing from a fetch that covered its date is no longer listed there.
SELECT
    "fetch_id" AS listing_fetch_id,
    -- Empty for pages fetched before the fetch log existed and migrated into it.
    NULLIF("run_id", '') AS crawl_run_id,
    CAST("fetched_at" AS timestamp with time zone) AS fetched_at,
    CAST("selectedStartDate" AS date) AS window_start_date,
    CAST("selectedEndDate" AS date) AS window_end_date,
    CAST("todayDate" AS date) AS bbc_today_date,
    "source_file" AS listing_file
FROM {{ source('bbc_sport', 'listing_fetches') }}
