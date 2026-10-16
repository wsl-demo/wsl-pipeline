-- Everyone named in a matchday squad (starters and the whole bench), one row
-- per player per match, with the match's date and season attached.
--
-- `has_appeared` separates players who actually took part from unused
-- substitutes; both are part of the squad for that match.
--
-- Matches, players and teams are keyed on their Opta IDs. BBC's own IDs stay
-- in staging; the team's Opta ID is looked up from the match's team list
-- because the lineup tables only carry BBC's team slug.
--
-- `recency_rank` = 1 is a player's most recent squad selection.
SELECT
    p.opta_match_id,
    p.opta_player_id,
    t.opta_team_id,
    {{ season_of(uk_local_date('m.kicked_off_at')) }} AS season,
    p.display_name,
    p.name_first,
    p.name_last,
    p.name_shirt,
    p."position",
    p.shirt_number,
    p.is_starter,
    p.is_captain,
    (p.is_starter OR p.substituted_on_minute IS NOT NULL) AS has_appeared,
    m.kicked_off_at,
    ROW_NUMBER() OVER (
        PARTITION BY p.opta_player_id
        ORDER BY m.kicked_off_at DESC, p.opta_match_id DESC
    ) AS recency_rank
FROM {{ ref('stg_bbc_sport__match_players') }} AS p
INNER JOIN {{ ref('stg_bbc_sport__matches') }} AS m
    ON p.opta_match_id = m.opta_match_id
INNER JOIN {{ ref('stg_bbc_sport__match_teams') }} AS t
    ON p.opta_match_id = t.opta_match_id
   AND p.bbc_team_id = t.bbc_team_id
