-- One row per employment period of a manager in a club: from the first match
-- BBC recorded them in charge of the club to the last match of an unbroken run.
--
-- A manager who leaves and later returns to the same club gets one row per
-- stint. Stints are found by walking a club's matches in kick-off order and
-- starting a new one whenever the manager changes (gaps and islands).
--
-- A manager is current when their last match is the latest match we have for
-- the club. The club's own latest is used, not the data's, because clubs do not
-- all play on the same days.
WITH team_matches AS (
    SELECT
        t.opta_team_id,
        t.bbc_manager_id,
        t.manager_name,
        t.opta_match_id,
        m.kicked_off_at,
        MAX(m.kicked_off_at) OVER (
            PARTITION BY t.opta_team_id
        ) AS club_latest_kicked_off_at
    FROM {{ ref('stg_bbc_sport__match_teams') }} AS t
    INNER JOIN {{ ref('stg_bbc_sport__matches') }} AS m
        ON t.opta_match_id = m.opta_match_id
),

managed AS (
    SELECT
        *,
        -- Consecutive matches under one manager share this difference, so it
        -- labels the stint.
        ROW_NUMBER() OVER (
            PARTITION BY opta_team_id
            ORDER BY kicked_off_at, opta_match_id
        )
        - ROW_NUMBER() OVER (
            PARTITION BY opta_team_id, bbc_manager_id
            ORDER BY kicked_off_at, opta_match_id
        ) AS stint_id
    FROM team_matches
),

stints AS (
    SELECT
        bbc_manager_id,
        opta_team_id,
        stint_id,
        ANY_VALUE(manager_name) AS manager_name,
        ARG_MIN(opta_match_id, kicked_off_at) AS first_match_opta_id,
        MIN(kicked_off_at) AS first_match_kicked_off_at,
        ARG_MAX(opta_match_id, kicked_off_at) AS last_match_opta_id,
        MAX(kicked_off_at) AS last_match_kicked_off_at,
        MAX(kicked_off_at) = MAX(club_latest_kicked_off_at) AS is_current
    FROM managed
    GROUP BY bbc_manager_id, opta_team_id, stint_id
)

SELECT
    bbc_manager_id,
    manager_name,
    opta_team_id,
    first_match_opta_id,
    first_match_kicked_off_at,
    last_match_opta_id,
    last_match_kicked_off_at,
    is_current
FROM stints
