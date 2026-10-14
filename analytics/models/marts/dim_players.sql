-- Attributes of a player, one row per player. Measures live in
-- fct_player_appearances; nothing here counts events.
WITH latest_appearance AS (
    SELECT
        player_id,
        team_id AS current_team_id,
        name_first,
        name_last,
        name_shirt,
        display_name,
        shirt_number
    FROM {{ ref('int_players_joined_to_matches') }}
    WHERE recency_rank = 1
),

-- The position a player has started in most often. The tie-break on
-- last_start_at and then position keeps the answer deterministic, which a bare
-- mode() would not.
most_common_position AS (
    SELECT
        player_id,
        "position"
    FROM (
        SELECT
            player_id,
            "position",
            ROW_NUMBER() OVER (
                PARTITION BY player_id
                ORDER BY starts DESC, last_start_at DESC, "position"
            ) AS position_rank
        FROM {{ ref('int_players_starts_aggregated_by_position') }}
    ) AS ranked
    WHERE position_rank = 1
),

-- A team's name is recorded per match, so take it from the same match that
-- decided current_team_id.
current_team AS (
    SELECT DISTINCT
        team_id,
        team_name
    FROM {{ ref('stg_bbc_sport__match_teams') }}
)

SELECT
    latest_appearance.player_id,
    latest_appearance.name_first,
    latest_appearance.name_last,
    latest_appearance.name_shirt,
    latest_appearance.display_name,
    latest_appearance.shirt_number,
    latest_appearance.current_team_id,
    current_team.team_name AS current_team_name,
    most_common_position."position" AS most_common_start_position
FROM latest_appearance
LEFT JOIN most_common_position
    ON latest_appearance.player_id = most_common_position.player_id
LEFT JOIN current_team
    ON latest_appearance.current_team_id = current_team.team_id
