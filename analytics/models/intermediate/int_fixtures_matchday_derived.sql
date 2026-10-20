-- The matchday of every fixture: its place in the season's schedule, counted
-- from 1. Every team plays once per matchday, but the matches of one matchday
-- are not played on one day; a postponed match is played weeks after the others.
-- BBC does not send a matchday, so it is derived here from each team's order of
-- play, with no cut-off on how far apart in time two matches may be.
--
-- 1. A team's nth match, by date, is usually its nth matchday. A postponed match
--    is played later than scheduled, so for its two teams it is numbered too
--    high and every match played in between is numbered one too low. A match
--    therefore takes the higher of its two teams' numbers: the team that has not
--    postponed anything usually has the right one. Where that gives a team the
--    same matchday twice, neither of the two matches is trusted.
-- 2. Each distrusted match is placed on a matchday that is still free for both
--    of its teams, but only when exactly one matchday fits. Placing a match can
--    leave another with a single fit, so this repeats `fill_passes` times.
-- 3. A match that still has no single fit gets no matchday. That is a decision
--    about ambiguity, not a claim that the match was postponed.
--
-- Matches come from BBC's listings, as the `fixtures` mart's do: each match
-- once, at the date BBC lists it now, which for a played match is the day it
-- was played. A match BBC no longer lists has no date to place it by, so it is
-- left out and gets no matchday. The mart reads this model, not the other way
-- round, so that it can take the matchday from here.
{% set fill_passes = 3 %}
WITH seasonal_matches AS (
    SELECT
        opta_match_id,
        opta_home_team_id,
        opta_away_team_id,
        match_date,
        kicked_off_at,
        {{ season_of('match_date') }} AS season
    FROM {{ ref('int_matches_listing_state_derived') }}
    WHERE no_longer_listed_at IS NULL
),

-- Each team meets every other twice, so a season has 2 * (teams - 1) matchdays.
season_sizes AS (
    SELECT
        season,
        2 * (COUNT(DISTINCT opta_team_id) - 1) AS matchday_count
    FROM (
        SELECT season, opta_home_team_id AS opta_team_id FROM seasonal_matches
        UNION ALL
        SELECT season, opta_away_team_id FROM seasonal_matches
    )
    GROUP BY season
),

matchday_numbers AS (
    SELECT
        season,
        UNNEST(RANGE(1, matchday_count + 1)) AS matchday
    FROM season_sizes
),

-- Step 1: number each team's matches in the order they are played.
team_matches AS (
    SELECT
        opta_match_id,
        season,
        'home' AS side,
        opta_home_team_id AS opta_team_id,
        match_date,
        kicked_off_at
    FROM seasonal_matches
    UNION ALL
    SELECT
        opta_match_id,
        season,
        'away',
        opta_away_team_id,
        match_date,
        kicked_off_at
    FROM seasonal_matches
),

team_match_numbers AS (
    SELECT
        opta_match_id,
        season,
        side,
        opta_team_id,
        ROW_NUMBER() OVER (
            PARTITION BY season, opta_team_id
            ORDER BY match_date, kicked_off_at, opta_match_id
        ) AS team_match_number
    FROM team_matches
),

sequenced AS (
    SELECT
        seasonal_matches.opta_match_id,
        seasonal_matches.season,
        seasonal_matches.opta_home_team_id,
        seasonal_matches.opta_away_team_id,
        GREATEST(home.team_match_number, away.team_match_number) AS matchday
    FROM seasonal_matches
    INNER JOIN team_match_numbers AS home
        ON seasonal_matches.opta_match_id = home.opta_match_id
       AND home.side = 'home'
    INNER JOIN team_match_numbers AS away
        ON seasonal_matches.opta_match_id = away.opta_match_id
       AND away.side = 'away'
),

sequenced_team_matchdays AS (
    SELECT opta_match_id, season, opta_home_team_id AS opta_team_id, matchday FROM sequenced
    UNION ALL
    SELECT opta_match_id, season, opta_away_team_id, matchday FROM sequenced
),

-- A team given the same matchday twice: one of the two is displaced, and
-- nothing here says which.
contested_team_matchdays AS (
    SELECT season, opta_team_id, matchday
    FROM sequenced_team_matchdays
    GROUP BY season, opta_team_id, matchday
    HAVING COUNT(*) > 1
),

placed_0 AS (
    SELECT
        opta_match_id,
        season,
        opta_home_team_id,
        opta_away_team_id,
        matchday,
        'in_sequence' AS matchday_placement
    FROM sequenced
    WHERE NOT EXISTS (
        SELECT 1
        FROM sequenced_team_matchdays AS claims
        INNER JOIN contested_team_matchdays AS contested
            ON claims.season = contested.season
           AND claims.opta_team_id = contested.opta_team_id
           AND claims.matchday = contested.matchday
        WHERE claims.opta_match_id = sequenced.opta_match_id
    )
)

-- Step 2: place what is left, one pass at a time. A pass uses only matches
-- placed by earlier passes, so the order matches are visited in changes nothing.
{% for fill_pass in range(1, fill_passes + 1) %}
,

open_matchdays_{{ fill_pass }} AS (
    SELECT
        seasonal_matches.opta_match_id,
        seasonal_matches.season,
        seasonal_matches.opta_home_team_id,
        seasonal_matches.opta_away_team_id,
        matchday_numbers.matchday
    FROM seasonal_matches
    INNER JOIN matchday_numbers
        ON seasonal_matches.season = matchday_numbers.season
    WHERE seasonal_matches.opta_match_id NOT IN (SELECT opta_match_id FROM placed_{{ fill_pass - 1 }})
      AND NOT EXISTS (
        SELECT 1
        FROM placed_{{ fill_pass - 1 }} AS placed
        WHERE placed.season = matchday_numbers.season
          AND placed.matchday = matchday_numbers.matchday
          AND (
              placed.opta_home_team_id IN (seasonal_matches.opta_home_team_id, seasonal_matches.opta_away_team_id)
              OR placed.opta_away_team_id IN (seasonal_matches.opta_home_team_id, seasonal_matches.opta_away_team_id)
          )
      )
),

only_fit_{{ fill_pass }} AS (
    SELECT
        opta_match_id,
        season,
        opta_home_team_id,
        opta_away_team_id,
        MIN(matchday) AS matchday
    FROM open_matchdays_{{ fill_pass }}
    GROUP BY opta_match_id, season, opta_home_team_id, opta_away_team_id
    HAVING COUNT(*) = 1
),

placed_{{ fill_pass }} AS (
    SELECT * FROM placed_{{ fill_pass - 1 }}
    UNION ALL
    -- Two matches fitting the same matchday for one team cannot both go there.
    SELECT
        opta_match_id,
        season,
        opta_home_team_id,
        opta_away_team_id,
        matchday,
        'filled_gap'
    FROM only_fit_{{ fill_pass }} AS fit
    WHERE NOT EXISTS (
        SELECT 1
        FROM only_fit_{{ fill_pass }} AS rival
        WHERE rival.opta_match_id <> fit.opta_match_id
          AND rival.season = fit.season
          AND rival.matchday = fit.matchday
          AND (
              rival.opta_home_team_id IN (fit.opta_home_team_id, fit.opta_away_team_id)
              OR rival.opta_away_team_id IN (fit.opta_home_team_id, fit.opta_away_team_id)
          )
    )
)
{% endfor %}

-- Step 3: whatever is not placed has no matchday.
SELECT
    seasonal_matches.opta_match_id,
    seasonal_matches.season,
    CAST(placed.matchday AS integer) AS matchday,
    COALESCE(placed.matchday_placement, 'unplaced') AS matchday_placement
FROM seasonal_matches
LEFT JOIN placed_{{ fill_passes }} AS placed
    ON seasonal_matches.opta_match_id = placed.opta_match_id
