-- Tripwire for the `strip_urn` macro: every staged id derived from a URN must be the
-- short form. A row here means BBC sent a URN with a prefix the macro doesn't
-- know, which would otherwise leave two formats mixed in one column.
{% set checks = [
    ('stg_bbc_sport__matches', 'bbc_match_id'),
    ('stg_bbc_sport__match_officials', 'bbc_match_id'),
    ('stg_bbc_sport__match_teams', 'bbc_match_id'),
    ('stg_bbc_sport__match_players', 'bbc_match_id'),
    ('stg_bbc_sport__match_pitch_layout', 'bbc_match_id'),
    ('stg_bbc_sport__match_actions', 'bbc_match_id'),
    ('stg_bbc_sport__match_player_cards', 'bbc_match_id'),
    ('stg_bbc_sport__player_match_stats', 'bbc_match_id'),
    ('stg_bbc_sport__team_match_stats', 'bbc_match_id'),
    ('stg_bbc_sport__matches', 'bbc_tournament_id'),
    ('stg_bbc_sport__matches', 'bbc_venue_id'),
    ('stg_bbc_sport__matches', 'bbc_home_team_id'),
    ('stg_bbc_sport__matches', 'bbc_away_team_id'),
    ('stg_bbc_sport__match_officials', 'bbc_official_id'),
    ('stg_bbc_sport__match_teams', 'bbc_team_id'),
    ('stg_bbc_sport__match_players', 'bbc_team_id'),
    ('stg_bbc_sport__match_players', 'bbc_player_id'),
    ('stg_bbc_sport__match_players', 'bbc_substituted_off_for_player_id'),
    ('stg_bbc_sport__match_players', 'bbc_substituted_on_for_player_id'),
    ('stg_bbc_sport__match_pitch_layout', 'bbc_team_id'),
    ('stg_bbc_sport__match_pitch_layout', 'bbc_player_id'),
    ('stg_bbc_sport__match_actions', 'bbc_team_id'),
    ('stg_bbc_sport__match_actions', 'bbc_player_id'),
    ('stg_bbc_sport__match_player_cards', 'bbc_team_id'),
    ('stg_bbc_sport__match_player_cards', 'bbc_player_id'),
    ('stg_bbc_sport__player_match_stats', 'bbc_team_id'),
    ('stg_bbc_sport__player_match_stats', 'bbc_player_id'),
    ('stg_bbc_sport__team_match_stats', 'bbc_team_id'),
] %}
{% for model, column in checks %}
SELECT '{{ model }}' AS model, '{{ column }}' AS column_name, {{ column }} AS value
FROM {{ ref(model) }}
WHERE {{ column }} LIKE 'urn:%'
{% if not loop.last %}UNION ALL{% endif %}
{% endfor %}
