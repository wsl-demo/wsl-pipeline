-- Once a fixture has been played it exists twice: on the fixtures page and as a
-- result. They must name the same teams the same way round, or one of the two
-- is mis-parsed somewhere.
SELECT
    f.opta_match_id
FROM {{ ref('stg_bbc_sport__fixtures') }} AS f
INNER JOIN {{ ref('stg_bbc_sport__matches') }} AS m
    ON f.opta_match_id = m.opta_match_id
WHERE f.opta_home_team_id <> m.opta_home_team_id
   OR f.opta_away_team_id <> m.opta_away_team_id
