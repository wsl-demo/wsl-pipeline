-- Every player/team/season that appears in a matchday squad must be a squad
-- member, or squad_members silently drops people.
SELECT DISTINCT
    season,
    opta_team_id,
    opta_player_id
FROM {{ ref('matchday_squad_members') }}
EXCEPT
SELECT
    season,
    opta_team_id,
    opta_player_id
FROM {{ ref('squad_members') }}
