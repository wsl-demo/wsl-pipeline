-- `kicked_off_at` comes from the kickoff BBC displays, because the page's own
-- `startDateTime` was found to be wrong for about one match in seven. This
-- checks the displayed time against a clock BBC does not edit by hand: a
-- substitution records both the wall-clock time it happened and the match
-- clock (`63:57`), so wall clock minus match clock is the moment of kickoff.
--
-- How close that estimate lands depends on the half (measured over all 431
-- matches once kickoffs were fixed):
--
-- - First half: within 2.3 minutes of kickoff. Allowed: 10 minutes either way.
--   Only about one match in eight has a first-half substitution.
-- - Second half: the match clock stops for half-time, so the estimate is 15 to
--   48 minutes after kickoff (median 19). Allowed: 10 to 50 minutes after.
--   Every match has one, but a kickoff that is out by less than half an hour
--   can pass this check.
--
-- Against the old `startDateTime` kickoffs, the two checks together caught 37
-- of the 66 wrong ones and none of the right ones.
WITH substitutions AS (
    SELECT
        {{ analytics.strip_urn('"match_urn"', 'event') }} AS bbc_match_id,
        "substitutedOff_periodId" AS period_id,
        CAST("substitutedOff_timestamp" AS timestamp with time zone)
            - to_seconds({{ analytics.match_clock_seconds('"substitutedOff_timeMinSec"') }})
            AS implied_kickoff
    FROM {{ source('bbc_sport', 'match_players') }}
    WHERE "substitutedOff_timestamp" IS NOT NULL
),

implied AS (
    SELECT
        bbc_match_id,
        MIN(implied_kickoff) FILTER (WHERE period_id = '1') AS first_half_implied_kickoff,
        MIN(implied_kickoff) FILTER (WHERE period_id = '2') AS second_half_implied_kickoff
    FROM substitutions
    GROUP BY bbc_match_id
),

compared AS (
    SELECT
        m.bbc_match_id,
        m.kicked_off_at,
        i.first_half_implied_kickoff,
        i.second_half_implied_kickoff,
        (EPOCH(i.first_half_implied_kickoff) - EPOCH(m.kicked_off_at)) / 60
            AS first_half_minutes_after,
        (EPOCH(i.second_half_implied_kickoff) - EPOCH(m.kicked_off_at)) / 60
            AS second_half_minutes_after
    FROM {{ ref('stg_bbc_sport__matches') }} AS m
    INNER JOIN implied AS i
        ON m.bbc_match_id = i.bbc_match_id
)

SELECT *
FROM compared
WHERE ABS(first_half_minutes_after) > 10
   OR second_half_minutes_after NOT BETWEEN 10 AND 50
