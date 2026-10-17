-- When each player in a matchday squad was on the pitch: one row per player
-- per match, with the moment they entered and the moment they left.
--
-- A starter enters at kickoff and a substitute when they came on. A player
-- leaves when substituted off or sent off, whichever came first. A player still
-- on at the final whistle has no leaving moment, because the source doesn't
-- record when a match ended. An unused substitute has neither.
--
-- Entries and exits are read from the same action rows the match_actions mart
-- publishes, so a player's window and the actions tested against it agree.
WITH entries AS (
    SELECT
        opta_match_id,
        opta_player_id,
        regulation_minute,
        injury_minute
    FROM {{ ref('int_match_actions_unioned') }}
    WHERE action_type = 'substituted_on'
),
exits AS (
    -- A card shown after a player was substituted off came on the bench and
    -- did not take them off the pitch, so only the first exit counts.
    SELECT
        opta_match_id,
        opta_player_id,
        regulation_minute,
        injury_minute,
        match_minute,
        ROW_NUMBER() OVER (
            PARTITION BY opta_match_id, opta_player_id
            ORDER BY match_minute
        ) AS exit_order
    FROM {{ ref('int_match_actions_unioned') }}
    WHERE action_type IN ('substituted_off', 'second_yellow', 'red_card')
),
windows AS (
    SELECT
        p.opta_match_id,
        p.opta_player_id,
        -- entered: kickoff for a starter, the substitution for anyone who came on
        CASE WHEN p.is_starter THEN 0 ELSE e.regulation_minute END AS entered_regulation_minute,
        CASE WHEN p.is_starter THEN 0 ELSE e.injury_minute END AS entered_injury_minute,
        x.regulation_minute AS exit_regulation_minute,
        x.injury_minute AS exit_injury_minute,
        x.match_minute AS exit_match_minute
    FROM {{ ref('stg_bbc_sport__match_players') }} AS p
    LEFT JOIN entries AS e
        ON p.opta_match_id = e.opta_match_id
       AND p.opta_player_id = e.opta_player_id
    LEFT JOIN exits AS x
        ON p.opta_match_id = x.opta_match_id
       AND p.opta_player_id = x.opta_player_id
       AND x.exit_order = 1
)
SELECT
    opta_match_id,
    opta_player_id,
    entered_regulation_minute,
    entered_injury_minute,
    {{ match_minute('entered_regulation_minute', 'entered_injury_minute') }}
        AS entered_match_minute,
    -- A player who never came on cannot leave, even if carded on the bench.
    CASE WHEN entered_regulation_minute IS NOT NULL THEN exit_regulation_minute END
        AS left_regulation_minute,
    CASE WHEN entered_regulation_minute IS NOT NULL THEN exit_injury_minute END
        AS left_injury_minute,
    CASE WHEN entered_regulation_minute IS NOT NULL THEN exit_match_minute END
        AS left_match_minute
FROM windows
