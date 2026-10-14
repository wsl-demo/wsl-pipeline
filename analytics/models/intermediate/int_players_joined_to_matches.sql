-- Every appearance a player made, with the match date attached so downstream
-- models can order by recency without repeating the join.
--
-- `recency_rank` = 1 is a player's most recent appearance. This replaces the
-- JOIN + ROW_NUMBER() that dim_players previously performed twice.
SELECT
    p.match_id,
    p.player_id,
    p.team_id,
    p.display_name,
    p.name_first,
    p.name_last,
    p.name_shirt,
    p."position",
    p.shirt_number,
    p.is_starter,
    p.is_captain,
    m.start_date_time,
    ROW_NUMBER() OVER (
        PARTITION BY p.player_id
        ORDER BY m.start_date_time DESC, p.match_id DESC
    ) AS recency_rank
FROM {{ ref('stg_bbc_sport__match_players') }} AS p
INNER JOIN {{ ref('stg_bbc_sport__matches') }} AS m
    ON p.match_id = m.match_id
