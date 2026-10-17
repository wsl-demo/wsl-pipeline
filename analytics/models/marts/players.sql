-- Who a player is: names and biography, one row per player, keyed on Opta's
-- player ID. Nothing here depends on a season; which team a player was in,
-- and when, is squad_members.
--
-- Every player in either source is here. BBC Sport knows the players named in a
-- matchday squad; wsl_football's squad lists know everyone in a current squad,
-- including players not yet named in a match. Names prefer BBC's, falling back
-- to wsl_football's; biography comes only from wsl_football.
WITH selections AS (
    SELECT
        opta_player_id,
        name_first,
        name_last,
        name_shirt,
        display_name,
        ROW_NUMBER() OVER (
            PARTITION BY opta_player_id
            ORDER BY kicked_off_at DESC, opta_match_id DESC
        ) AS recency_rank
    FROM {{ ref('int_players_joined_to_matches') }}
),

latest_squad_selection AS (
    SELECT
        opta_player_id,
        name_first,
        name_last,
        name_shirt,
        display_name
    FROM selections
    WHERE recency_rank = 1
),

biography AS (
    SELECT
        opta_player_id,
        first_name,
        last_name,
        short_name,
        shirt_name,
        nationality,
        nationality_iso_code,
        birth_date,
        height_cm,
        weight_kg
    FROM {{ ref('stg_wsl_football__squad_players') }}
)

SELECT
    COALESCE(latest_squad_selection.opta_player_id, biography.opta_player_id) AS opta_player_id,
    COALESCE(latest_squad_selection.name_first, biography.first_name) AS name_first,
    COALESCE(latest_squad_selection.name_last, biography.last_name) AS name_last,
    COALESCE(latest_squad_selection.name_shirt, biography.shirt_name) AS name_shirt,
    COALESCE(latest_squad_selection.display_name, biography.short_name) AS display_name,
    biography.nationality,
    biography.nationality_iso_code,
    biography.height_cm,
    biography.weight_kg,
    biography.birth_date
FROM latest_squad_selection
FULL OUTER JOIN biography
    ON latest_squad_selection.opta_player_id = biography.opta_player_id
