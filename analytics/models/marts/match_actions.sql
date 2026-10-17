-- Everything recorded as happening at a moment in a match: goals, assists,
-- cards and substitutions. One row per action per player; a substitution is
-- two rows, one for each player in the swap.
SELECT
    -- keys
    opta_match_id,
    opta_player_id,
    opta_other_player_id,
    -- strings
    action_type,
    -- numerics: when
    regulation_minute,
    injury_minute,
    match_minute
FROM {{ ref('int_match_actions_unioned') }}
