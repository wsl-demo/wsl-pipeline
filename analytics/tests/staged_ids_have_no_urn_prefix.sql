-- Tripwire for the `strip_urn` macro: every staged id derived from a URN must be the
-- short form. A row here means BBC sent a URN with a prefix the macro doesn't
-- know, which would otherwise leave two formats mixed in one column.
{% set checks = [
    ('stg_bbc_sport__matches', 'match_id'),
    ('stg_bbc_sport__match_officials', 'match_id'),
    ('stg_bbc_sport__match_teams', 'match_id'),
    ('stg_bbc_sport__match_players', 'match_id'),
    ('stg_bbc_sport__match_pitch_layout', 'match_id'),
    ('stg_bbc_sport__match_actions', 'match_id'),
    ('stg_bbc_sport__match_player_cards', 'match_id'),
    ('stg_bbc_sport__player_match_stats', 'match_id'),
    ('stg_bbc_sport__team_match_stats', 'match_id'),
    ('stg_bbc_sport__matches', 'tournament_id'),
    ('stg_bbc_sport__matches', 'venue_id'),
    ('stg_bbc_sport__matches', 'home_team_id'),
    ('stg_bbc_sport__matches', 'away_team_id'),
    ('stg_bbc_sport__match_officials', 'official_id'),
    ('stg_bbc_sport__match_teams', 'team_id'),
    ('stg_bbc_sport__match_players', 'team_id'),
    ('stg_bbc_sport__match_players', 'player_id'),
    ('stg_bbc_sport__match_players', 'substituted_off_for_player_id'),
    ('stg_bbc_sport__match_players', 'substituted_on_for_player_id'),
    ('stg_bbc_sport__match_pitch_layout', 'team_id'),
    ('stg_bbc_sport__match_pitch_layout', 'player_id'),
    ('stg_bbc_sport__match_actions', 'team_id'),
    ('stg_bbc_sport__match_actions', 'player_id'),
    ('stg_bbc_sport__match_player_cards', 'team_id'),
    ('stg_bbc_sport__match_player_cards', 'player_id'),
    ('stg_bbc_sport__player_match_stats', 'team_id'),
    ('stg_bbc_sport__player_match_stats', 'player_id'),
    ('stg_bbc_sport__team_match_stats', 'team_id'),
] %}
{% for model, column in checks %}
SELECT '{{ model }}' AS model, '{{ column }}' AS column_name, {{ column }} AS value
FROM {{ ref(model) }}
WHERE {{ column }} LIKE 'urn:%'
{% if not loop.last %}UNION ALL{% endif %}
{% endfor %}
