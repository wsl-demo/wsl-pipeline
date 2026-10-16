{#
    Descriptions shared by columns that mean the same thing in several BBC
    staging models. Each column's YAML adds the raw field it is built from,
    which differs between models.
#}

{% docs bbc_match_id %}
BBC's match ID: `s-` followed by Opta's match ID, e.g. `s-1cd4kbemthwb8obzgso3i01lg`.
The same match carries the same ID in every BBC table, and keeps it when it moves
from fixtures to results.
{% enddocs %}

{% docs opta_match_id %}
Opta's match ID: `bbc_match_id` with its `s-` removed by the `opta_id_from_bbc_id`
macro, which returns null for an ID without the `s-`. Downstream models key matches on it.
{% enddocs %}

{% docs bbc_player_id %}
BBC's player ID: `s-` followed by Opta's player ID, e.g. `s-9t8eb24gwj56ucggp7x0n0ewa`.
{% enddocs %}

{% docs opta_player_id %}
Opta's player ID: `bbc_player_id` with its `s-` removed by the `opta_id_from_bbc_id`
macro, which returns null for an ID without the `s-`. The key players share with
wsl_football; downstream models key players on it.
{% enddocs %}

{% docs bbc_team_id %}
BBC's team ID: a slug such as `arsenal-ladies` or `manchester-city-women`. Not an
Opta ID. For Opta's team ID, join `stg_bbc_sport__match_teams` on `bbc_match_id`
and `bbc_team_id`.
{% enddocs %}

{% docs opta_team_id %}
Opta's team ID, which BBC calls the participant ID, e.g. `5rurqie3qt1qav9ir5mkqinn`
(Arsenal). Downstream models key teams on it.
{% enddocs %}

{% docs regulation_time_minutes %}
The regulation match minute the event happened in: the number before the `'` in
raw `timeLabel_value`, so `90'+4` gives 90.
{% enddocs %}

{% docs injury_time_minutes %}
Minutes into added time: the number after the `+` in raw `timeLabel_value`, so
`90'+4` gives 4. Zero when there is no `+`.
{% enddocs %}

{% docs match_period %}
Which part of the match the event belongs to, worked out from
`regulation_time_minutes`: 1 for minutes 1–45, 2 for 46–90, 3 for 91–105 and 4
for 106–120 (3 and 4 are the halves of extra time). Added time belongs to the
period it extends, so `45'+2` is period 1. Null past minute 120.
{% enddocs %}
