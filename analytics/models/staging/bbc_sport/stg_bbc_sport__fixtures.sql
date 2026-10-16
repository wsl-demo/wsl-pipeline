-- Scheduled matches. Teams are named by their Opta ID, which BBC calls the
-- participant ID, so no lookup is needed to relate them to played matches.
--
-- `date_heading` carries no year ("Sunday 18th October"), so the date is built
-- from `month` ("2026-10") plus the day number. The ordinal suffix is always
-- two letters (st, nd, rd, th). `kickoff_time` is "TBC" until BBC confirms it.
-- Times carry no zone; UK football kicks off in UK local time.
WITH parsed AS (
    SELECT
        -- Unlike other BBC tables, the fixtures page sends the match ID without
        -- a URN prefix (`s-` + Opta ID), so there is nothing to strip.
        "event_id" AS bbc_match_id,
        "home_participant_id" AS opta_home_team_id,
        "away_participant_id" AS opta_away_team_id,
        CAST(
            "month" || '-' || LPAD(
                LEFT(
                    {{ dbt.split_part('"date_heading"', "' '", 2) }},
                    LENGTH({{ dbt.split_part('"date_heading"', "' '", 2) }}) - 2
                ),
                2,
                '0'
            ) AS date
        ) AS match_date,
        NULLIF("kickoff_time", 'TBC') AS kickoff_time_local
    FROM {{ source('bbc_sport', 'fixtures') }}
)

SELECT
    bbc_match_id,
    {{ analytics.opta_id_from_bbc_id('bbc_match_id') }} AS opta_match_id,
    opta_home_team_id,
    opta_away_team_id,
    match_date,
    kickoff_time_local IS NULL AS is_kickoff_time_tbc,
    CASE
        WHEN kickoff_time_local IS NOT NULL
        THEN CAST(
            CAST(match_date AS varchar) || ' ' || kickoff_time_local AS timestamp
        ) AT TIME ZONE 'Europe/London'
    END AS kicked_off_at
FROM parsed
