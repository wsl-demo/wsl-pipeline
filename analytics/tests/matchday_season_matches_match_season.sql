-- Season is derived by the `season_of` macro in more than one model rather than
-- inherited through a join. This is the guard against those call sites ever
-- disagreeing: a squad row must carry the same season as its match.
SELECT
    s.opta_match_id
FROM {{ ref('matchday_squad_members') }} AS s
INNER JOIN {{ ref('matches') }} AS m
    ON s.opta_match_id = m.opta_match_id
WHERE s.season <> m.season
