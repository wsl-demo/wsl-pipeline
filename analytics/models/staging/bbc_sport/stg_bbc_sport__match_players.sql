WITH parsed AS (
    SELECT
        {{ analytics.strip_urn('"match_urn"', 'event') }} AS match_id,
        {{ analytics.strip_urn('"team_urn"', 'team') }} AS team_id,
        -- (all) general player information --
        {{ analytics.strip_urn('"urn"', 'player') }} AS player_id,
        {{ analytics.opta_id_from_bbc_id(analytics.strip_urn('"urn"', 'player')) }} AS opta_player_id,
        "displayName" AS display_name,
        "name_first" AS name_first,
        "name_last" AS name_last,
        "name_shirt" AS name_shirt,
        -- Every non-starter carries `position` = 'Substitute', which is roster
        -- status rather than a playing position and already lives in
        -- `is_starter`. Null it out so `position` means one thing only.
        NULLIF("position", 'Substitute') AS "position",
        CAST(NULLIF("shirtNumber", '') AS integer) AS shirt_number,
        CASE WHEN "source_player_list" = 'starters' THEN true ELSE false END AS is_starter,
        CASE WHEN "isCaptain" = 'true' THEN true ELSE false END AS is_captain,
        CAST(NULLIF("formationPlace", '') AS integer) AS formation_place,
        -- (starter) substituted off --
        CAST("substitutedOff_periodId" AS integer) AS substituted_off_period,
        "substitutedOff_timeMinSec" AS raw_substituted_off_min_sec,
        {{ analytics.match_clock_seconds('"substitutedOff_timeMinSec"') }} AS substituted_off_time_seconds,
        {{ analytics.match_clock_minute('"substitutedOff_timeMinSec"') }} AS substituted_off_minute,
        "substitutedOff_reason" AS substituted_off_reason,
        {{ analytics.strip_urn('"substitutedOff_playerOnUrn"', 'player') }} AS substituted_off_for_player_id,
        -- (sub) substituted on --
        CAST("substitutedOn_periodId" AS integer) AS substituted_on_period,
        "substitutedOn_timeMinSec" AS raw_substituted_on_min_sec,
        {{ analytics.match_clock_seconds('"substitutedOn_timeMinSec"') }} AS substituted_on_time_seconds,
        {{ analytics.match_clock_minute('"substitutedOn_timeMinSec"') }} AS substituted_on_minute,
        "substitutedOn_reason" AS substituted_on_reason,
        {{ analytics.strip_urn('"substitutedOn_playerOffUrn"', 'player') }} AS substituted_on_for_player_id
    FROM {{ source('bbc_sport', 'match_players') }}
)
SELECT
    match_id,
    team_id,
    player_id,
    opta_player_id,
    display_name,
    name_first,
    name_last,
    name_shirt,
    "position",
    shirt_number,
    is_starter,
    is_captain,
    formation_place,
    -- (starter) substituted off --
    substituted_off_reason,
    substituted_off_for_player_id,
    substituted_off_period,
    substituted_off_minute,
    {{ regulation_time_from_minute('substituted_off_minute', 'substituted_off_period') }}
        AS substituted_off_regulation_time,
    {{ injury_time_from_minute('substituted_off_minute', 'substituted_off_period') }}
        AS substituted_off_injury_time,
    raw_substituted_off_min_sec,
    substituted_off_time_seconds,
    -- (sub) substituted on --
    substituted_on_reason,
    substituted_on_for_player_id,
    substituted_on_period,
    substituted_on_minute,
    {{ regulation_time_from_minute('substituted_on_minute', 'substituted_on_period') }}
        AS substituted_on_regulation_time,
    {{ injury_time_from_minute('substituted_on_minute', 'substituted_on_period') }}
        AS substituted_on_injury_time,
    raw_substituted_on_min_sec,
    substituted_on_time_seconds
FROM parsed
