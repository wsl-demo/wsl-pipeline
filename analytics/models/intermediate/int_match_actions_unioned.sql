-- Everything recorded as happening at a moment in a match, in one shape:
-- goals, assists, cards and substitutions. One row per action per player, so a
-- substitution is two rows, one for the player going off and one for the
-- player coming on.
--
-- Goals come from match_actions and cards from match_player_cards. Sendings-off
-- appear in both sources, so only the cards source contributes them.
WITH goals AS (
    SELECT
        opta_match_id,
        opta_player_id,
        CASE
            WHEN is_goal THEN 'goal'
            WHEN is_penalty THEN 'penalty_goal'
            WHEN is_own_goal THEN 'own_goal'
        END AS action_type,
        CAST(NULL AS varchar) AS opta_other_player_id,
        regulation_time_minutes AS regulation_minute,
        injury_time_minutes AS injury_minute
    FROM {{ ref('stg_bbc_sport__match_actions') }}
    WHERE is_goal OR is_penalty OR is_own_goal
),
assists AS (
    SELECT
        opta_match_id,
        opta_player_id,
        'assist' AS action_type,
        CAST(NULL AS varchar) AS opta_other_player_id,
        regulation_minute,
        injury_minute
    FROM {{ ref('int_assists_joined_to_players') }}
),
cards AS (
    SELECT
        opta_match_id,
        opta_player_id,
        CASE
            WHEN is_yellow_card THEN 'yellow_card'
            WHEN is_second_yellow THEN 'second_yellow'
            WHEN is_direct_red THEN 'red_card'
        END AS action_type,
        CAST(NULL AS varchar) AS opta_other_player_id,
        regulation_time_minutes AS regulation_minute,
        injury_time_minutes AS injury_minute
    FROM {{ ref('stg_bbc_sport__match_player_cards') }}
),
substitutions_off AS (
    SELECT
        opta_match_id,
        opta_player_id,
        'substituted_off' AS action_type,
        opta_substituted_off_for_player_id AS opta_other_player_id,
        substituted_off_regulation_time AS regulation_minute,
        substituted_off_injury_time AS injury_minute
    FROM {{ ref('stg_bbc_sport__match_players') }}
    WHERE substituted_off_period IS NOT NULL
),
substitutions_on AS (
    SELECT
        opta_match_id,
        opta_player_id,
        'substituted_on' AS action_type,
        opta_substituted_on_for_player_id AS opta_other_player_id,
        substituted_on_regulation_time AS regulation_minute,
        substituted_on_injury_time AS injury_minute
    FROM {{ ref('stg_bbc_sport__match_players') }}
    WHERE substituted_on_period IS NOT NULL
),
actions AS (
    SELECT * FROM goals
    UNION ALL
    SELECT * FROM assists
    UNION ALL
    SELECT * FROM cards
    UNION ALL
    SELECT * FROM substitutions_off
    UNION ALL
    SELECT * FROM substitutions_on
)
SELECT
    opta_match_id,
    opta_player_id,
    opta_other_player_id,
    action_type,
    regulation_minute,
    injury_minute,
    {{ match_minute('regulation_minute', 'injury_minute') }} AS match_minute
FROM actions
