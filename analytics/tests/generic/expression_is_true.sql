{% test expression_is_true(model, expression) %}
SELECT *
FROM {{ model }}
WHERE NOT ({{ expression }})
{% endtest %}
