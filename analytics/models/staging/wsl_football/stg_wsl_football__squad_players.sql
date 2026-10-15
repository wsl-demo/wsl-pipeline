-- Biographical data only. The source also carries each player's club, shirt
-- number and a copy of the club's logos and links on every row; none of that is
-- used, because team membership comes from BBC Sport.
--
-- `dateOfBirth` is written two ways ("2006-02-03T00:00:00Z" and "2010-09-10"),
-- so only its first ten characters are read. Height is centimetres and weight
-- kilograms; the source does not say, but the values (153-185, 40-81) only fit
-- those units.
SELECT
    "optaId" AS opta_player_id,
    "mediaFirstName" AS first_name,
    "mediaLastName" AS last_name,
    "shortName" AS short_name,
    NULLIF("shirtName", '') AS shirt_name,
    "nationality" AS nationality,
    "nationalityIsoCode" AS nationality_iso_code,
    CAST(LEFT(NULLIF("dateOfBirth", ''), 10) AS date) AS birth_date,
    CAST(NULLIF("height", '') AS integer) AS height_cm,
    CAST(NULLIF("weight", '') AS integer) AS weight_kg
FROM {{ source('wsl_football', 'squad_players') }}
