-- One row per season in the data. Built from `matches`, so it covers every
-- season that has a result or a scheduled fixture.
--
-- The current season is the latest one present, which is deterministic and does
-- not depend on the day the build runs.
WITH team_seasons AS (
    SELECT season, opta_home_team_id AS opta_team_id FROM {{ ref('matches') }}
    UNION
    SELECT season, opta_away_team_id FROM {{ ref('matches') }}
),

team_counts AS (
    SELECT
        season,
        CAST(COUNT(*) AS integer) AS team_count
    FROM team_seasons
    GROUP BY season
),

season_matches AS (
    SELECT
        season,
        CAST(COUNT(*) AS integer) AS matches_total,
        CAST(COUNT(*) FILTER (WHERE match_status = 'played') AS integer) AS matches_played,
        MIN(match_date) AS first_match_date,
        MAX(match_date) AS last_match_date
    FROM {{ ref('matches') }}
    GROUP BY season
)

SELECT
    season_matches.season,
    team_counts.team_count,
    season_matches.matches_total,
    season_matches.matches_played,
    season_matches.season = MAX(season_matches.season) OVER () AS is_current,
    season_matches.first_match_date,
    season_matches.last_match_date
FROM season_matches
INNER JOIN team_counts
    ON season_matches.season = team_counts.season
