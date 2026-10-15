SELECT
    -- The match URN without its prefix (BBC calls matches "events"). Unlike
    -- the page slug in `source_match_id`, which exists only once a match has
    -- been played, the URN is known beforehand, so scheduled fixtures carry
    -- the same ID.
    {{ analytics.strip_urn('"urn"', 'event') }} AS match_id,
    {{ parse_iso_timestamp("startDateTime") }} AS kicked_off_at,
    "tournament_disambiguatedName" AS tournament_name,
    {{ analytics.strip_urn('"tournament_urn"', 'tournament') }} AS tournament_id,
    "venue_name",
    {{ analytics.strip_urn('"venue_urn"', 'venue') }} AS venue_id,
    CAST("attendance_value" AS integer) AS attendance_count,
    CASE WHEN "stage_name" LIKE 'Regular Season' THEN true ELSE false END AS is_regular_season,
    CASE WHEN "periodLabel_value" LIKE 'FT' THEN true ELSE false END AS is_full_time,
    {{ analytics.strip_urn('"home_urn"', 'team') }} AS home_team_id,
    "home_id" AS home_opta_team_id,
    CAST("home_runningScores_halftime" AS integer) AS home_score_halftime,
    CAST("home_runningScores_fulltime" AS integer) AS home_score_fulltime,
    {{ analytics.strip_urn('"away_urn"', 'team') }} AS away_team_id,
    "away_id" AS away_opta_team_id,
    CAST("away_runningScores_halftime" AS integer) AS away_score_halftime,
    CAST("away_runningScores_fulltime" AS integer) AS away_score_fulltime,
    "winner" AS winner_side
FROM {{ source('bbc_sport', 'matches') }}
