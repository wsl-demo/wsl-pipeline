-- One row per player per match: the event grain that dim_players used to
-- summarise into six pivoted columns. Counting starts by position is now an
-- aggregation over this model rather than a stored measure on the dimension.
SELECT
    -- keys
    a.match_id,
    a.player_id,
    a.team_id,
    -- degenerate attributes of the appearance itself
    a.is_starter,
    a."position",
    a.shirt_number,
    a.is_captain,
    -- substitution measures
    p.substituted_on_minute,
    p.substituted_on_reason,
    p.substituted_off_minute,
    p.substituted_off_reason,
    -- performance measures, nullable because the source is sparse
    s.minutes_played,
    s.goals,
    s.assists,
    s.chances_created,
    s.shots_total,
    s.shots_on_target,
    s.saves,
    s.total_passes,
    s.pass_accuracy_pct,
    s.total_tackles,
    s.tackles_won_pct,
    s.fouls_committed,
    s.fouls_won
FROM {{ ref('int_players_joined_to_matches') }} AS a
INNER JOIN {{ ref('stg_bbc_sport__match_players') }} AS p
    ON a.match_id = p.match_id
   AND a.player_id = p.player_id
LEFT JOIN {{ ref('int_player_match_stats_pivoted') }} AS s
    ON a.match_id = s.match_id
   AND a.player_id = s.player_id
