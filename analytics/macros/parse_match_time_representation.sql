{#
  BBC writes clock events two ways:

    timeLabel_value   "45'+2"   regulation minute, optionally plus added time
    timeMinSec        "67:30"   minutes and seconds elapsed

  The macros below parse both, and share one definition of what a match period
  is so that the two representations cannot drift apart.
#}

{% macro match_time_part(column_name, part) %}
  split_part(replace({{ column_name }}, '''', ''), '+', {{ part }})
{% endmacro %}

{% macro match_regulation_time(column_name) %}
    cast({{ match_time_part(column_name, 1) }} as integer)
{% endmacro %}

{% macro match_added_time(column_name) %}
  case
    when {{ column_name }} is not null
    then coalesce(cast(nullif({{ match_time_part(column_name, 2) }}, '') as integer), 0)
  end
{% endmacro %}

{#
  A match has up to four periods: 1 and 2 are the halves of normal time, 3 and 4
  the halves of extra time. The arms cascade, so each states only its upper
  bound. Anything past 120 falls through to null rather than being folded into
  the last period.
#}
{% macro match_period(regulation_time_column) %}
  case
    when {{ regulation_time_column }} <= 45 then 1
    when {{ regulation_time_column }} <= 90 then 2
    when {{ regulation_time_column }} <= 105 then 3
    when {{ regulation_time_column }} <= 120 then 4
  end
{% endmacro %}

{#
  The regulation minute each period ends on. Extra-time halves are 15 minutes
  rather than 45, so this deliberately cannot be expressed as 45 * period.
#}
{% macro period_regulation_end(period_column) %}
  case {{ period_column }}
    when 1 then 45
    when 2 then 90
    when 3 then 105
    when 4 then 120
  end
{% endmacro %}

{% macro match_clock_seconds(column_name) %}
  cast({{ dbt.split_part(column_name, "':'", 1) }} as integer) * 60
  + cast({{ dbt.split_part(column_name, "':'", 2) }} as integer)
{% endmacro %}

{% macro match_clock_minute(column_name) %}
  cast({{ dbt.split_part(column_name, "':'", 1) }} as integer) + 1
{% endmacro %}

{#
  Split an elapsed minute into the part inside regulation time and the part in
  added time. The explicit null guard matters: without it a null minute would
  fail the `<=` comparison and fall through to the else arm, which would report
  the end of the period as though the event had happened.
#}
{% macro regulation_time_from_minute(minute_column, period_column) %}
  case
    when {{ minute_column }} is null then null
    when {{ minute_column }} <= {{ period_regulation_end(period_column) }}
      then {{ minute_column }}
    else {{ period_regulation_end(period_column) }}
  end
{% endmacro %}

{% macro injury_time_from_minute(minute_column, period_column) %}
  case
    when {{ minute_column }} is null then null
    when {{ minute_column }} <= {{ period_regulation_end(period_column) }} then 0
    else {{ minute_column }} - ({{ period_regulation_end(period_column) }})
  end
{% endmacro %}

{#
  One exact decimal for a moment in the match, in the form BBC labels it with:
  `45'+3` becomes 45.03 and `46'` becomes 46.00. Added time only happens at the
  end of a period, so these sort in match order and can be compared with
  BETWEEN. They are not durations: 46.00 - 45.03 is not how long passed.
  Decimal rather than float, so a moment computed in two places compares equal.
#}
{% macro match_minute(regulation_minute_column, injury_minute_column) %}
  cast({{ regulation_minute_column }} + {{ injury_minute_column }} / 100.0 as decimal(4, 2))
{% endmacro %}
