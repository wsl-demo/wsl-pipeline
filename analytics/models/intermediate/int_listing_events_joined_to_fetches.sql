-- Every observation of a match in BBC's listings: one row per match per fetch.
-- The scraper stores a listing page once per distinct content, so a fetch that
-- found the page unchanged shares its stored page with earlier fetches; joining
-- the fetch log to the stored pages' matches gives back each fetch's view.
SELECT
    fetches.listing_fetch_id,
    fetches.crawl_run_id,
    fetches.fetched_at AS observed_at,
    fetches.window_start_date,
    fetches.window_end_date,
    events.bbc_match_id,
    events.opta_match_id,
    events.bbc_status,
    events.bbc_status_note,
    events.match_date,
    events.is_kickoff_time_tbc,
    events.kicked_off_at,
    events.opta_home_team_id,
    events.opta_away_team_id,
    events.home_score_fulltime,
    events.away_score_fulltime,
    events.winner_side,
    events.bbc_match_page_id,
    events.tournament_name
FROM {{ ref('stg_bbc_sport__listing_fetches') }} AS fetches
INNER JOIN {{ ref('stg_bbc_sport__listing_events') }} AS events
    ON fetches.listing_file = events.listing_file
