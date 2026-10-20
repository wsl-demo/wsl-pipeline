-- Every change to a match's listed kickoff, one row per change: a date moved, a
-- time moved, or a TBC time confirmed. Each observation is compared with the
-- match's previous one, so a reschedule is a recorded fact with the moment BBC
-- was first seen showing it, rather than an overwrite.
--
-- `changed_at` is when the change was first observed, not when BBC made it:
-- it happened at some point since the previous observation.
WITH sequenced AS (
    SELECT
        bbc_match_id,
        opta_match_id,
        observed_at,
        match_date,
        kicked_off_at,
        is_kickoff_time_tbc,
        LAG(observed_at) OVER by_time AS previous_observed_at,
        LAG(match_date) OVER by_time AS previous_match_date,
        LAG(kicked_off_at) OVER by_time AS previous_kicked_off_at,
        LAG(is_kickoff_time_tbc) OVER by_time AS previous_is_kickoff_time_tbc
    FROM {{ ref('int_listing_events_joined_to_fetches') }}
    WINDOW by_time AS (PARTITION BY bbc_match_id ORDER BY observed_at, listing_fetch_id)
)

SELECT
    bbc_match_id,
    opta_match_id,
    observed_at AS changed_at,
    previous_observed_at,
    previous_match_date,
    previous_kicked_off_at,
    previous_is_kickoff_time_tbc,
    match_date,
    kicked_off_at,
    is_kickoff_time_tbc
FROM sequenced
WHERE previous_observed_at IS NOT NULL
  AND (
      match_date IS DISTINCT FROM previous_match_date
      OR kicked_off_at IS DISTINCT FROM previous_kicked_off_at
      OR is_kickoff_time_tbc IS DISTINCT FROM previous_is_kickoff_time_tbc
  )
