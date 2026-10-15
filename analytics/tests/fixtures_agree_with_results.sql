-- Once a fixture has been played it exists twice: on the fixtures page and as a
-- result. They must name the same teams the same way round, or one of the two
-- is mis-parsed somewhere.
SELECT
    f.match_id
FROM {{ ref('stg_bbc_sport__fixtures') }} AS f
INNER JOIN {{ ref('stg_bbc_sport__matches') }} AS m
    ON f.match_id = m.match_id
WHERE f.home_opta_team_id <> m.home_opta_team_id
   OR f.away_opta_team_id <> m.away_opta_team_id
