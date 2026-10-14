-- How often each player started in each position, one row per combination.
--
-- This is the long-format replacement for the six hardcoded
-- SUM(CASE WHEN position = '...') expressions that dim_players used to carry: a
-- new position appears here as a new row rather than needing a new column.
-- `position` is never null in this model because staging nulls it for
-- non-starters and only starts are counted.
SELECT
    player_id,
    "position",
    COUNT(*) AS starts,
    MAX(start_date_time) AS last_start_at
FROM {{ ref('int_players_joined_to_matches') }}
WHERE is_starter
GROUP BY player_id, "position"
