-- Each match as BBC lists it now: its latest observation, when BBC first and
-- last listed it, and whether BBC has since stopped listing it.
--
-- A listing names every match BBC dates within its window, whatever its
-- status. So when a fetch made after a match's latest observation covered the
-- date that observation gave, the match was not on it: had it been, that fetch
-- would be its latest observation. BBC no longer lists it on that date and,
-- since nothing has listed it since, on any date the crawl covers. That is how
-- a postponement or a removal first shows. No reason is claimed: the match may
-- be postponed without a new date, moved beyond the crawl's horizon, or
-- withdrawn.
--
-- Nothing here reads the build's clock. A match last seen `PreEvent` whose
-- kickoff has since passed is still scheduled, as of `last_listed_at`.
WITH observations AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY bbc_match_id
            ORDER BY observed_at DESC, listing_fetch_id DESC
        ) AS recency,
        MIN(observed_at) OVER (PARTITION BY bbc_match_id) AS first_listed_at
    FROM {{ ref('int_listing_events_joined_to_fetches') }}
),

latest AS (
    SELECT *
    FROM observations
    WHERE recency = 1
),

-- The first later fetch whose window covered the latest listed date.
unlisted AS (
    SELECT
        latest.bbc_match_id,
        MIN(fetches.fetched_at) AS no_longer_listed_at
    FROM latest
    INNER JOIN {{ ref('stg_bbc_sport__listing_fetches') }} AS fetches
        ON fetches.fetched_at > latest.observed_at
       AND latest.match_date BETWEEN fetches.window_start_date AND fetches.window_end_date
    GROUP BY latest.bbc_match_id
)

SELECT
    latest.bbc_match_id,
    latest.opta_match_id,
    latest.opta_home_team_id,
    latest.opta_away_team_id,
    latest.bbc_status,
    latest.bbc_status_note,
    latest.match_date,
    latest.is_kickoff_time_tbc,
    latest.kicked_off_at,
    latest.home_score_fulltime,
    latest.away_score_fulltime,
    latest.winner_side,
    latest.bbc_match_page_id,
    latest.tournament_name,
    latest.first_listed_at,
    latest.observed_at AS last_listed_at,
    unlisted.no_longer_listed_at
FROM latest
LEFT JOIN unlisted
    ON latest.bbc_match_id = unlisted.bbc_match_id
