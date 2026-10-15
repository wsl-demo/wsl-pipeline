{#
    BBC identifies a player as `s-` followed by the player's Opta ID, and the
    league's own site (wsl_football) publishes the bare Opta ID. This drops the
    `s-` so the two sources can be joined on one key.

    Anything that does not start with `s-` becomes NULL rather than being
    passed through: a wrong key should fail the join and the
    `player_ids_are_s_prefixed` test, not quietly match nothing.
#}
{% macro opta_id_from_bbc_id(column) -%}
    CASE
        WHEN {{ column }} LIKE 's-%' THEN substr({{ column }}, 3)
    END
{%- endmacro %}
