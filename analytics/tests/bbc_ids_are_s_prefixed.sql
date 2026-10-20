-- Each opta_*_id derived from a BBC ID is that ID minus its `s-` prefix, and
-- `opta_id_from_bbc_id` returns null for anything else. A BBC ID without the
-- prefix would get a null Opta ID and silently fail to join, so surface the BBC
-- value here, in every staging table that derives one.
{% set checks = [
    ('stg_bbc_sport__matches', 'bbc_match_id'),
    ('stg_bbc_sport__listing_events', 'bbc_match_id'),
    ('stg_bbc_sport__match_pages', 'bbc_match_id'),
    ('stg_bbc_sport__match_officials', 'bbc_match_id'),
    ('stg_bbc_sport__match_teams', 'bbc_match_id'),
    ('stg_bbc_sport__match_players', 'bbc_match_id'),
    ('stg_bbc_sport__match_pitch_layout', 'bbc_match_id'),
    ('stg_bbc_sport__match_actions', 'bbc_match_id'),
    ('stg_bbc_sport__match_player_cards', 'bbc_match_id'),
    ('stg_bbc_sport__player_match_stats', 'bbc_match_id'),
    ('stg_bbc_sport__team_match_stats', 'bbc_match_id'),
    ('stg_bbc_sport__match_players', 'bbc_player_id'),
    ('stg_bbc_sport__match_players', 'bbc_substituted_off_for_player_id'),
    ('stg_bbc_sport__match_players', 'bbc_substituted_on_for_player_id'),
    ('stg_bbc_sport__match_pitch_layout', 'bbc_player_id'),
    ('stg_bbc_sport__match_actions', 'bbc_player_id'),
    ('stg_bbc_sport__match_player_cards', 'bbc_player_id'),
    ('stg_bbc_sport__player_match_stats', 'bbc_player_id'),
] %}
{% for model, column in checks %}
SELECT '{{ model }}' AS model, '{{ column }}' AS column_name, {{ column }} AS value
FROM {{ ref(model) }}
WHERE {{ column }} NOT LIKE 's-%'
{% if not loop.last %}UNION ALL{% endif %}
{% endfor %}
