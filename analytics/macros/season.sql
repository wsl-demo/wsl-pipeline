{#
    A football season runs from summer to the following summer, so a match
    played on or after 1 July belongs to the season that starts that year.

        2026-06-30  ->  2025-2026
        2026-07-01  ->  2026-2027
        2027-01-15  ->  2026-2027

    This is the one definition of the rule. Models that need a season call it
    on a date instead of inheriting it through a join, which keeps the match
    model from becoming a hub every other model hangs off.

    `date_column` must be a date, not a timestamp: use `uk_local_date` to turn
    a kickoff timestamp into the date the match was played on.
#}
{% macro season_of(date_column) -%}
    CASE
        WHEN EXTRACT(month FROM {{ date_column }}) >= 7
        THEN CAST(EXTRACT(year FROM {{ date_column }}) AS varchar)
            || '-' || CAST(EXTRACT(year FROM {{ date_column }}) + 1 AS varchar)
        ELSE CAST(EXTRACT(year FROM {{ date_column }}) - 1 AS varchar)
            || '-' || CAST(EXTRACT(year FROM {{ date_column }}) AS varchar)
    END
{%- endmacro %}

{#
    The calendar date of a kickoff in UK local time, which is the date the match
    was played on. A 23:30 UTC kickoff in summer is already tomorrow in London.
#}
{% macro uk_local_date(timestamp_column) -%}
    CAST({{ timestamp_column }} AT TIME ZONE 'Europe/London' AS date)
{%- endmacro %}
