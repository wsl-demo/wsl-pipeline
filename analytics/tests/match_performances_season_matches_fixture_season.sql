-- Season is derived by the `season_of` macro in more than one model rather than
-- inherited through a join. This is the guard against those call sites ever
-- disagreeing: a squad row must carry the same season as its fixture.
SELECT
    p.opta_match_id
FROM {{ ref('match_performances') }} AS p
INNER JOIN {{ ref('fixtures') }} AS f
    ON p.opta_match_id = f.opta_match_id
WHERE p.season <> f.season
