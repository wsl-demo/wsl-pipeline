-- League points each side earned from a match: 3 for a win, 1 for a draw,
-- 0 for a loss. This is a football scoring rule rather than a cleanup of the
-- source, so it lives here instead of in staging.
SELECT
    match_id,
    CASE winner_side
        WHEN 'home' THEN 3
        WHEN 'away' THEN 0
        WHEN 'draw' THEN 1
        END AS home_points,
    CASE winner_side
        WHEN 'home' THEN 0
        WHEN 'away' THEN 3
        WHEN 'draw' THEN 1
        END AS away_points
FROM {{ ref('stg_bbc_sport__matches') }}
