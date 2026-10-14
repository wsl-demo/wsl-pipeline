{% macro parse_iso_timestamp(column_name) %}
  {{ return(adapter.dispatch('parse_iso_timestamp')(column_name)) }}
{% endmacro %}

{% macro default__parse_iso_timestamp(column_name) %}
  cast({{ column_name }} as timestamp with time zone)
{% endmacro %}

{% macro clickhouse__parse_iso_timestamp(column_name) %}
  parseDateTime64BestEffort({{ column_name }}, 3, 'UTC')
{% endmacro %}