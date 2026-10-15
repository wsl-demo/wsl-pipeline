-- Everyone named in a matchday squad (starters and the whole bench), one row
-- per player per match, with the match's date and season attached.
--
-- `has_appeared` separates players who actually took part from unused
-- substitutes; both are part of the squad for that match.
--
-- Players and teams are keyed on their Opta IDs. BBC's own player ID and team
-- slug stay in staging; the team's Opta ID is looked up from the match's team
-- list because the lineup tables only carry the slug.
--
-- `recency_rank` = 1 is a player's most recent squad selection.
SELECT
    p.match_id,
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
        ORDER BY m.kicked_off_at DESC, p.match_id DESC
    ) AS recency_rank
FROM {{ ref('stg_bbc_sport__match_players') }} AS p
INNER JOIN {{ ref('stg_bbc_sport__matches') }} AS m
    ON p.match_id = m.match_id
INNER JOIN {{ ref('stg_bbc_sport__match_teams') }} AS t
    ON p.match_id = t.match_id
   AND p.team_id = t.team_id
