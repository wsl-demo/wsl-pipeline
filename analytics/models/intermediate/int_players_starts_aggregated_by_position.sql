-- How often each player started in each position for each team in each season,
-- one row per combination.
--
-- Position is a per-season, per-team attribute: a player can change both, so
-- "most common position" only means something within a squad. `position` is
-- never null here because staging nulls it for non-starters and only starts
-- are counted.
SELECT
    season,
    opta_team_id,
    opta_player_id,
    "position",
    COUNT(*) AS starts,
    MAX(kicked_off_at) AS last_started_at
FROM {{ ref('int_players_joined_to_matches') }}
WHERE is_starter
GROUP BY season, opta_team_id, opta_player_id, "position"
