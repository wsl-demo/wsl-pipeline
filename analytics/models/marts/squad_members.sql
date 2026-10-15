-- Who was in a team's squad in a season: one row per player per team per
-- season, with that player's biography joined in.
--
-- Squads are inferred. A player is a member of a team's squad in a season when
-- they were named in one of that team's matchday squads that season, so a
-- player who never made a matchday squad (injured all year, say) is not here.
-- Biography comes from wsl_football's current squad lists, so it is present for
-- players still in a squad and null for those who have left.
--
-- A player who moved mid-season has a row for each team. Which season a match
-- belongs to comes from the same `season_of` rule as every other model.
WITH selections AS (
    SELECT
        season,
        opta_team_id,
        opta_player_id,
        match_id,
        kicked_off_at,
        is_starter,
        has_appeared,
        shirt_number,
        name_first,
        name_last,
        display_name,
        ROW_NUMBER() OVER (
            PARTITION BY season, opta_team_id, opta_player_id
            ORDER BY kicked_off_at DESC, match_id DESC
        ) AS recency_rank
    FROM {{ ref('int_players_joined_to_matches') }}
),

membership AS (
    SELECT
        season,
        opta_team_id,
        opta_player_id,
        CAST(COUNT(*) AS integer) AS matches_in_squad,
        CAST(COUNT(*) FILTER (WHERE has_appeared) AS integer) AS matches_appeared,
        CAST(COUNT(*) FILTER (WHERE is_starter) AS integer) AS matches_started,
        MIN({{ uk_local_date('kicked_off_at') }}) AS first_squad_date,
        MAX({{ uk_local_date('kicked_off_at') }}) AS last_squad_date
    FROM selections
    GROUP BY season, opta_team_id, opta_player_id
),

latest AS (
    SELECT
        season,
        opta_team_id,
        opta_player_id,
        name_first,
        name_last,
        display_name,
        shirt_number
    FROM selections
    WHERE recency_rank = 1
),

-- Ties are broken on the most recent start and then position, which keeps the
-- answer deterministic where a bare mode() would not.
main_position AS (
    SELECT
        season,
        opta_team_id,
        opta_player_id,
        "position" AS most_common_start_position
    FROM (
        SELECT
            season,
            opta_team_id,
            opta_player_id,
            "position",
            ROW_NUMBER() OVER (
                PARTITION BY season, opta_team_id, opta_player_id
                ORDER BY starts DESC, last_started_at DESC, "position"
            ) AS position_rank
        FROM {{ ref('int_players_starts_aggregated_by_position') }}
    ) AS ranked
    WHERE position_rank = 1
)

SELECT
    membership.opta_player_id,
    membership.opta_team_id,
    membership.season,
    latest.name_first,
    latest.name_last,
    latest.display_name,
    main_position.most_common_start_position,
    biography.nationality,
    biography.nationality_iso_code,
    latest.shirt_number,
    membership.matches_in_squad,
    membership.matches_appeared,
    membership.matches_started,
    biography.height_cm,
    biography.weight_kg,
    biography.birth_date,
    membership.first_squad_date,
    membership.last_squad_date
FROM membership
INNER JOIN latest
    ON membership.season = latest.season
   AND membership.opta_team_id = latest.opta_team_id
   AND membership.opta_player_id = latest.opta_player_id
LEFT JOIN main_position
    ON membership.season = main_position.season
   AND membership.opta_team_id = main_position.opta_team_id
   AND membership.opta_player_id = main_position.opta_player_id
LEFT JOIN {{ ref('stg_wsl_football__squad_players') }} AS biography
    ON membership.opta_player_id = biography.opta_player_id
