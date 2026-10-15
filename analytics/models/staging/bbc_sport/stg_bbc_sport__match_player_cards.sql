WITH parsed AS (
    SELECT
        {{ analytics.strip_urn('"match_urn"', 'event') }} AS match_id,
        {{ analytics.strip_urn('"playerUrn"', 'player') }} AS player_id,
        {{ analytics.opta_id_from_bbc_id(analytics.strip_urn('"playerUrn"', 'player')) }} AS opta_player_id,
        {{ analytics.strip_urn('"team_urn"', 'team') }} AS team_id,
        CASE WHEN "type" = 'Yellow Card' THEN true ELSE false END AS is_yellow_card,
        CASE WHEN "type" = 'Two Yellow Cards' THEN true ELSE false END AS is_second_yellow,
        CASE WHEN "type" = 'Red Card' THEN true ELSE false END AS is_direct_red,
        {{ analytics.match_regulation_time('"timeLabel_value"') }} AS regulation_time_minutes,
        {{ analytics.match_added_time('"timeLabel_value"') }} AS injury_time_minutes
    FROM {{ source('bbc_sport', 'match_player_cards') }}
)
SELECT
    match_id,
    player_id,
    opta_player_id,
    team_id,
    is_yellow_card,
    is_second_yellow,
    is_direct_red,
    regulation_time_minutes,
    injury_time_minutes,
    {{ analytics.match_period('regulation_time_minutes') }} AS "period"
FROM parsed
