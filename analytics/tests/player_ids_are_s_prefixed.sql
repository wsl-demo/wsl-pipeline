-- opta_player_id is player_id minus its `s-` prefix. A player ID without that
-- prefix would get a null Opta ID and silently fail to match wsl_football, so
-- surface it here, in every staging table that carries one.
SELECT 'match_players' AS model, player_id
FROM {{ ref('stg_bbc_sport__match_players') }}
WHERE player_id NOT LIKE 's-%'
UNION ALL
SELECT 'match_pitch_layout' AS model, player_id
FROM {{ ref('stg_bbc_sport__match_pitch_layout') }}
WHERE player_id NOT LIKE 's-%'
UNION ALL
SELECT 'match_actions' AS model, player_id
FROM {{ ref('stg_bbc_sport__match_actions') }}
WHERE player_id NOT LIKE 's-%'
UNION ALL
SELECT 'match_player_cards' AS model, player_id
FROM {{ ref('stg_bbc_sport__match_player_cards') }}
WHERE player_id NOT LIKE 's-%'
UNION ALL
SELECT 'player_match_stats' AS model, player_id
FROM {{ ref('stg_bbc_sport__player_match_stats') }}
WHERE player_id NOT LIKE 's-%'
