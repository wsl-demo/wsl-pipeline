-- Matches as BBC's listing pages listed them: one row per match per stored
-- page. A page that did not change between fetches is stored once, so the
-- fetches that saw it are joined on `listing_file` downstream
-- (`int_listing_events_joined_to_fetches`).
--
-- Every value is a state at the time of listing, and `bbc_status` says which:
-- the score is a running score and `winner_side` the side leading while it is
-- `MidEvent`; they are a result only once it is `PostEvent`.
WITH parsed AS (
    SELECT
        "source_file" AS listing_file,
        -- Listings send the match ID without a URN prefix: `s-` + Opta's ID.
        "id" AS bbc_match_id,
        "status" AS bbc_status,
        "statusComment_value" AS bbc_status_note,
        CAST("date_isoDate" AS date) AS match_date,
        -- `startDateTime` is the kickoff in UTC, or a bare date while BBC has no
        -- time for it; `time_timeCertainty` says which.
        "time_timeCertainty" = 'false' AS is_kickoff_time_tbc,
        CASE
            WHEN "time_timeCertainty" = 'true'
            THEN CAST("startDateTime" AS timestamp with time zone)
        END AS kicked_off_at,
        "home_id" AS opta_home_team_id,
        "away_id" AS opta_away_team_id,
        {{ analytics.strip_urn('"home_urn"', 'team') }} AS bbc_home_team_id,
        {{ analytics.strip_urn('"away_urn"', 'team') }} AS bbc_away_team_id,
        CAST("home_score" AS integer) AS home_score,
        CAST("away_score" AS integer) AS away_score,
        CAST("home_runningScores_halftime" AS integer) AS home_score_halftime,
        CAST("away_runningScores_halftime" AS integer) AS away_score_halftime,
        CAST("home_runningScores_fulltime" AS integer) AS home_score_fulltime,
        CAST("away_runningScores_fulltime" AS integer) AS away_score_fulltime,
        "winner" AS winner_side,
        "tipoTopicId" AS bbc_match_page_id,
        "tournament_disambiguatedName" AS tournament_name,
        {{ analytics.strip_urn('"tournament_urn"', 'tournament') }} AS bbc_tournament_id,
        "tournament_id" AS opta_tournament_id
    FROM {{ source('bbc_sport', 'listing_events') }}
)

SELECT
    listing_file,
    bbc_match_id,
    {{ analytics.opta_id_from_bbc_id('bbc_match_id') }} AS opta_match_id,
    bbc_status,
    bbc_status_note,
    match_date,
    is_kickoff_time_tbc,
    kicked_off_at,
    opta_home_team_id,
    opta_away_team_id,
    bbc_home_team_id,
    bbc_away_team_id,
    home_score,
    away_score,
    home_score_halftime,
    away_score_halftime,
    home_score_fulltime,
    away_score_fulltime,
    winner_side,
    bbc_match_page_id,
    tournament_name,
    bbc_tournament_id,
    opta_tournament_id
FROM parsed
