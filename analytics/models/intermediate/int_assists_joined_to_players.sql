-- Every assist in a played match: one row per assist, with the player who made
-- it and when.
--
-- BBC lists assists only as labels on the match page, one per player per side,
-- such as `M. Fowler (38', 45'+2)`: a name, not an ID, and one time per assist.
-- The name is matched to the squad that side named for the match, on the
-- shortened name BBC also gives each squad member.
--
-- A shortened name is not unique within a squad: Tottenham's Angharad and Amy
-- James-Turner are both `A. James-Turner`. So the name is matched only among
-- squad members whose `assists` statistic for the match is above zero.
WITH assist_groups AS (
    -- `grouped_actions` is JSON text: a list of groups (only "Assists" so far),
    -- each with a list of labels per side.
    --
    -- The outer CAST repeats the type `from_json` already returns. DuckDB
    -- treats it as a no-op, but strict static analysis types `from_json` as
    -- text and rejects the UNNEST without it. Casting the JSON straight to the
    -- struct doesn't work: that cast fails on keys the struct doesn't list.
    SELECT
        opta_match_id,
        bbc_home_team_id,
        bbc_away_team_id,
        UNNEST(CAST(
            from_json(
                grouped_actions,
                '[{"groupName": {"fullName": "VARCHAR"}, "homeTeamActions": ["VARCHAR"], "awayTeamActions": ["VARCHAR"]}]'
            ) AS STRUCT("groupName" STRUCT("fullName" varchar), "homeTeamActions" varchar[], "awayTeamActions" varchar[])[]
        )) AS action_group
    FROM {{ ref('stg_bbc_sport__matches') }}
),
labels AS (
    SELECT
        opta_match_id,
        bbc_home_team_id AS bbc_team_id,
        UNNEST(action_group.homeTeamActions) AS label
    FROM assist_groups
    WHERE action_group.groupName.fullName = 'Assists'
    UNION ALL
    SELECT
        opta_match_id,
        bbc_away_team_id AS bbc_team_id,
        UNNEST(action_group.awayTeamActions) AS label
    FROM assist_groups
    WHERE action_group.groupName.fullName = 'Assists'
),
split_labels AS (
    -- The name is everything before the bracket; each comma-separated time
    -- inside it is one assist.
    SELECT
        opta_match_id,
        bbc_team_id,
        regexp_extract(label, '^(.*) \(', 1) AS display_name,
        UNNEST(string_split(regexp_extract(label, '\((.*)\)$', 1), ',')) AS untrimmed_time_label
    FROM labels
),
assists AS (
    -- Trimmed in its own step: strict static analysis rejects TRIM(UNNEST(...)).
    SELECT
        opta_match_id,
        bbc_team_id,
        display_name,
        TRIM(untrimmed_time_label) AS time_label
    FROM split_labels
),
assisting_names AS (
    -- One row per name among the squad members credited with an assist. If
    -- two such players share a name, the name can't say which one it was, so
    -- the player is left null.
    SELECT
        p.opta_match_id,
        p.bbc_team_id,
        p.display_name,
        CASE WHEN COUNT(*) = 1 THEN MIN(p.opta_player_id) END AS opta_player_id
    FROM {{ ref('stg_bbc_sport__match_players') }} AS p
    INNER JOIN {{ ref('int_player_match_stats_pivoted') }} AS s
        ON p.opta_match_id = s.opta_match_id
       AND p.opta_player_id = s.opta_player_id
    WHERE s.assists > 0
    GROUP BY p.opta_match_id, p.bbc_team_id, p.display_name
)
SELECT
    a.opta_match_id,
    -- Null if the name matches no one credited with an assist, or more than one,
    -- so the assist fails the marts' not_null tests instead of being dropped or
    -- credited twice.
    n.opta_player_id,
    {{ match_regulation_time('a.time_label') }} AS regulation_minute,
    {{ match_added_time('a.time_label') }} AS injury_minute
FROM assists AS a
LEFT JOIN assisting_names AS n
    ON a.opta_match_id = n.opta_match_id
   AND a.bbc_team_id = n.bbc_team_id
   AND a.display_name = n.display_name
