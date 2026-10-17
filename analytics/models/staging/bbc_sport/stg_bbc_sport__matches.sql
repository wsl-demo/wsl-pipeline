WITH parsed AS (
    SELECT
        -- The match URN without its prefix (BBC calls matches "events"): `s-`
        -- followed by Opta's match ID. Unlike the page slug in
        -- `source_match_id`, which exists only once a match has been played,
        -- the URN is known beforehand, so scheduled fixtures carry the same ID.
        {{ analytics.strip_urn('"urn"', 'event') }} AS bbc_match_id,
        -- BBC's match page slug, as sent. Staged for traceability only; nothing
        -- downstream needs it.
        "source_match_id" AS bbc_match_page_id,
        -- Kickoff as the match page displays it: `Sat 21 Oct 2023` and `12:30`,
        -- in UK local time. Raw `startDateTime` is not used: for about one
        -- match in seven it holds a different time, sometimes days out, and the
        -- substitution timestamps side with the displayed time every time.
        CAST(strptime("date", '%a %d %b %Y') AS date) AS kickoff_date_local,
        "time_displayTimeUK" AS kickoff_time_local,
        "tournament_disambiguatedName" AS tournament_name,
        -- The tournament URN's tail is a BBC slug (`womens-super-league`); BBC
        -- sends Opta's competition ID beside it as its own column.
        {{ analytics.strip_urn('"tournament_urn"', 'tournament') }} AS bbc_tournament_id,
        "tournament_id" AS opta_tournament_id,
        -- Opta's stage ID: one "Regular Season" stage per season.
        "stage_id" AS opta_stage_id,
        "venue_name",
        -- `s-` plus an ID that is probably Opta's but unconfirmed, so BBC-named.
        {{ analytics.strip_urn('"venue_urn"', 'venue') }} AS bbc_venue_id,
        CAST("attendance_value" AS integer) AS attendance_count,
        CASE WHEN "stage_name" LIKE 'Regular Season' THEN true ELSE false END AS is_regular_season,
        CASE WHEN "periodLabel_value" LIKE 'FT' THEN true ELSE false END AS is_full_time,
        -- Each team comes as a BBC slug in its URN and, separately, Opta's ID.
        {{ analytics.strip_urn('"home_urn"', 'team') }} AS bbc_home_team_id,
        "home_id" AS opta_home_team_id,
        CAST("home_runningScores_halftime" AS integer) AS home_score_halftime,
        CAST("home_runningScores_fulltime" AS integer) AS home_score_fulltime,
        {{ analytics.strip_urn('"away_urn"', 'team') }} AS bbc_away_team_id,
        "away_id" AS opta_away_team_id,
        CAST("away_runningScores_halftime" AS integer) AS away_score_halftime,
        CAST("away_runningScores_fulltime" AS integer) AS away_score_fulltime,
        "winner" AS winner_side,
        -- JSON text, as sent; parsing it changes the grain, so that happens
        -- downstream.
        "groupedActions" AS grouped_actions
    FROM {{ source('bbc_sport', 'matches') }}
)
SELECT
    bbc_match_id,
    {{ analytics.opta_id_from_bbc_id('bbc_match_id') }} AS opta_match_id,
    bbc_match_page_id,
    {{ uk_local_timestamp('kickoff_date_local', 'kickoff_time_local') }} AS kicked_off_at,
    tournament_name,
    bbc_tournament_id,
    opta_tournament_id,
    opta_stage_id,
    venue_name,
    bbc_venue_id,
    attendance_count,
    is_regular_season,
    is_full_time,
    bbc_home_team_id,
    opta_home_team_id,
    home_score_halftime,
    home_score_fulltime,
    bbc_away_team_id,
    opta_away_team_id,
    away_score_halftime,
    away_score_fulltime,
    winner_side,
    grouped_actions
FROM parsed
