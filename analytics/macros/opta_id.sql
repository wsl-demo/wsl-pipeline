{#
    BBC identifies players and matches as `s-` followed by the Opta ID, while
    the league's own site (wsl_football) and Opta itself use the bare ID. This
    drops the `s-` so BBC rows can be keyed on the Opta ID.

    Anything that does not start with `s-` becomes NULL rather than being
    passed through: a wrong key should fail the not_null tests on the
    `opta_*_id` columns and `bbc_ids_are_s_prefixed`, not quietly match nothing.
#}
{% macro opta_id_from_bbc_id(column) -%}
    CASE
        WHEN {{ column }} LIKE 's-%' THEN substr({{ column }}, 3)
    END
{%- endmacro %}
