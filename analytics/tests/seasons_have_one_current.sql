-- Exactly one season is current. Zero or several would make "the current
-- season" ambiguous for everything that filters on it.
SELECT
    current_seasons
FROM (
    SELECT COUNT(*) FILTER (WHERE is_current) AS current_seasons
    FROM {{ ref('seasons') }}
)
WHERE current_seasons <> 1
