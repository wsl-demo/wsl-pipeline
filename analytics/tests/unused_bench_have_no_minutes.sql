-- has_appeared is derived from starting or coming on. A player flagged as not
-- having appeared who nonetheless recorded playing time means the flag is wrong.
SELECT
    match_id,
    opta_player_id,
    minutes_played
FROM {{ ref('matchday_squad_members') }}
WHERE NOT has_appeared
  AND COALESCE(minutes_played, 0) > 0
