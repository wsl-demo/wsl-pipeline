-- Attributes of a team, one row per team, keyed on its Opta ID. A team's name
-- is recorded per match, so take it from the team's most recent match rather
-- than collapsing with DISTINCT, which would return two rows the day BBC
-- renames a club.
WITH ranked AS (
    SELECT
        t.opta_team_id,
        t.team_code,
        t.team_name,
        t.team_short_name,
        ROW_NUMBER() OVER (
            PARTITION BY t.opta_team_id
            ORDER BY m.kicked_off_at DESC, t.opta_match_id DESC
        ) AS recency_rank
    FROM {{ ref('stg_bbc_sport__match_teams') }} AS t
    INNER JOIN {{ ref('stg_bbc_sport__matches') }} AS m
        ON t.opta_match_id = m.opta_match_id
)

SELECT
    opta_team_id,
    team_code,
    team_name,
    team_short_name
FROM ranked
WHERE recency_rank = 1
