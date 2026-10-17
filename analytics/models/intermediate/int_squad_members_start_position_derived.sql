-- The position each player started in most often for each team in each season:
-- one row per player per team per season, for players who started at least
-- once.
--
-- Position is a per-season, per-team attribute: a player can change both, so
-- "most common position" only means something within a squad. `position` is
-- never null here because staging nulls it for non-starters and only starts
-- are counted.
WITH starts_by_position AS (
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
),

ranked AS (
    -- Ties are broken on the most recent start and then position, which keeps
    -- the answer deterministic where a bare mode() would not.
    SELECT
        season,
        opta_team_id,
        opta_player_id,
        "position",
        ROW_NUMBER() OVER (
            PARTITION BY season, opta_team_id, opta_player_id
            ORDER BY starts DESC, last_started_at DESC, "position"
        ) AS position_rank
    FROM starts_by_position
)

SELECT
    season,
    opta_team_id,
    opta_player_id,
    "position" AS most_common_start_position
FROM ranked
WHERE position_rank = 1
