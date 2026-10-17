-- Everyone named in a match's squad: one row per player per match, starters
-- and the whole bench. An unused substitute is part of the squad for that
-- match but did not appear; `has_appeared` tells them apart, so count
-- appearances with it rather than with rows.
--
-- The entered_ and left_ columns are the player's time on the pitch, in the
-- same form as `match_actions`, so an action can be tested against them.
SELECT
    -- keys
    a.opta_match_id,
    a.opta_player_id,
    a.opta_team_id,
    -- dates
    {{ uk_local_date('a.kicked_off_at') }} AS match_date,
    -- strings
    a.season,
    a."position",
    p.substituted_on_reason,
    p.substituted_off_reason,
    -- numerics: squad
    a.shirt_number,
    -- numerics: time on the pitch
    w.entered_regulation_minute,
    w.entered_injury_minute,
    w.entered_match_minute,
    w.left_regulation_minute,
    w.left_injury_minute,
    w.left_match_minute,
    -- numerics: performance, nullable because the source is sparse
    s.minutes_played,
    s.goals,
    s.assists,
    s.chances_created,
    s.shots_total,
    s.shots_on_target,
    s.saves,
    s.total_passes,
    s.pass_accuracy_percent,
    s.total_tackles,
    s.tackles_won_percent,
    s.fouls_committed,
    s.fouls_won,
    -- booleans
    a.is_starter,
    a.is_captain,
    a.has_appeared
FROM {{ ref('int_players_joined_to_matches') }} AS a
INNER JOIN {{ ref('stg_bbc_sport__match_players') }} AS p
    ON a.opta_match_id = p.opta_match_id
   AND a.opta_player_id = p.opta_player_id
INNER JOIN {{ ref('int_players_time_on_pitch_derived') }} AS w
    ON a.opta_match_id = w.opta_match_id
   AND a.opta_player_id = w.opta_player_id
LEFT JOIN {{ ref('int_player_match_stats_pivoted') }} AS s
    ON a.opta_match_id = s.opta_match_id
   AND a.opta_player_id = s.opta_player_id
