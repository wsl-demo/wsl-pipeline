WITH parsed AS (
    SELECT
        {{ analytics.strip_urn('"match_urn"', 'event') }} AS match_id,
        {{ analytics.strip_urn('"team_urn"', 'team') }} AS team_id,
        {{ analytics.strip_urn('"playerUrn"', 'player') }} AS player_id,
        {{ analytics.opta_id_from_bbc_id(analytics.strip_urn('"playerUrn"', 'player')) }} AS opta_player_id,
        CAST("action_index" AS integer) AS action_index,
        CAST("sub_index" AS integer) AS sub_index,
        CASE WHEN "type" = 'Own Goal' THEN true ELSE false END AS is_own_goal,
        CASE WHEN "type" = 'Goal' THEN true ELSE false END AS is_goal,
        CASE WHEN "type" = 'Red Card' THEN true ELSE false END AS is_direct_red,
        CASE WHEN "type" = 'Two Yellow Cards' THEN true ELSE false END AS is_second_yellow,
        CASE WHEN "type" = 'Penalty' THEN true ELSE false END AS is_penalty,
        {{ analytics.match_regulation_time('"timeLabel_value"') }} AS regulation_time_minutes,
        {{ analytics.match_added_time('"timeLabel_value"') }} AS injury_time_minutes
    FROM {{ source('bbc_sport', 'match_actions') }}
)
SELECT
    match_id,
    team_id,
    player_id,
    opta_player_id,
    action_index,
    sub_index,
    is_own_goal,
    is_goal,
    is_direct_red,
    is_second_yellow,
    is_penalty,
    regulation_time_minutes,
    injury_time_minutes,
    {{ analytics.match_period('regulation_time_minutes') }} AS "period"
FROM parsed
