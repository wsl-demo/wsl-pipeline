{#
    Drop BBC's constant `urn:bbc:sportsdata:football:<kind>:` prefix from a
    URN, leaving BBC's short id (`s-8euuw3bc...`, `everton-ladies`). Used only
    where the URN is the sole BBC ID for an entity; a field that already holds
    the short form (fixtures' `event_id`) is staged as sent.

    - Only a value that *starts with* the exact prefix is shortened. Anything
      else is passed through unchanged so it stays visible, and the
      `staged_ids_have_no_urn_prefix` test fails on it instead of mixed
      formats silently reaching the marts.
    - NULLs stay NULL.
    - `kind` is the URN's entity type: player, team, event (a match),
      tournament, venue or official.
#}
{% macro strip_urn(column, kind) -%}
    {%- set prefix = 'urn:bbc:sportsdata:football:' ~ kind ~ ':' -%}
    CASE
        WHEN {{ column }} LIKE '{{ prefix }}%'
        THEN substr({{ column }}, {{ prefix | length + 1 }})
        ELSE {{ column }}
    END
{%- endmacro %}
