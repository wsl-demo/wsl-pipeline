{#
    Descriptions for columns that keep their meaning from staging to the marts.
    Each says what the value is, wherever it appears; a model's YAML adds what
    is particular to that model, such as how staging derives the value or why a
    mart can hold nulls.
#}

{#  IDs  #}

{% docs opta_match_id %}
Opta's match ID, e.g. `1cd4kbemthwb8obzgso3i01lg`. BBC's match ID is the same
value with `s-` in front. Every model after staging joins matches on it.
{% enddocs %}

{% docs opta_player_id %}
Opta's player ID, e.g. `9t8eb24gwj56ucggp7x0n0ewa`: the key BBC Sport and
wsl_football share. BBC's player ID is the same value with `s-` in front. Every
model after staging joins players on it.
{% enddocs %}

{% docs opta_team_id %}
Opta's team ID, which BBC calls the participant ID, e.g.
`5rurqie3qt1qav9ir5mkqinn` (Arsenal). Every model after staging joins teams on it.
{% enddocs %}

{% docs opta_id_from_bbc_id %}
Derived from BBC's ID by the `opta_id_from_bbc_id` macro, which removes the `s-`
and returns null for an ID without it.
{% enddocs %}

{#  Time  #}

{% docs season %}
Season label, e.g. "2026-2027". A season runs from 1 July to 30 June; the
`season_of` macro assigns a match to one from the date it was played in the UK.
{% enddocs %}

{#
    Player statistics. Staged in long form (`stg_bbc_sport__player_match_stats`,
    one row per statistic), pivoted to columns by
    `int_player_match_stats_pivoted`, and published on `matchday_squad_members`.
    Facts about values ("never more than 90") were checked against the data on
    2026-10-16.
#}

{% docs minutes_played %}
Minutes the player was on the pitch, from BBC's `minsPlayed`. Never more than
90, so added time is not counted. Null for an unused substitute.
{% enddocs %}

{% docs goals %}
Goals the player scored, from BBC's `goals`. Penalties count and own goals do
not: summed over every match, it equals the `Goal` and `Penalty` actions in
`stg_bbc_sport__match_actions`. Null for a starting goalkeeper.
{% enddocs %}

{% docs assists %}
Assists, from BBC's `assists`. Null for a starting goalkeeper.
{% enddocs %}

{% docs chances_created %}
From BBC's `totalAssists`, which BBC labels "Chances created"; the column
follows the label. Never lower than `assists`, so assists count as chances
created. Null for a starting goalkeeper.
{% enddocs %}

{% docs shots_total %}
Shots, on and off target, from BBC's `shotsTotal`. Null for a starting goalkeeper.
{% enddocs %}

{% docs shots_on_target %}
Shots on target, from BBC's `shotsOnTarget`. Never more than `shots_total`. Null
for a starting goalkeeper.
{% enddocs %}

{% docs saves %}
Shots saved, from BBC's `shotsSaved`. Recorded only for starting goalkeepers;
null for everyone else.
{% enddocs %}

{% docs total_passes %}
Passes, from BBC's `totalPass`.
{% enddocs %}

{% docs pass_accuracy_percent %}
Share of the player's passes BBC counts as accurate, from 0 to 100, from BBC's
`accuratePassPercentage`.
{% enddocs %}

{% docs total_tackles %}
Tackles, from BBC's `totalTackle`. Null for most starting goalkeepers.
{% enddocs %}

{% docs tackles_won_percent %}
Share of the player's tackles won, from 0 to 100, from BBC's
`wonTacklePercentage`. Null for most starting goalkeepers.
{% enddocs %}

{% docs fouls_committed %}
Fouls the player committed, from BBC's `fouls`.
{% enddocs %}

{% docs fouls_won %}
Times the player was fouled, from BBC's `wasFouled`.
{% enddocs %}

{#
    Player biography. Only wsl_football has it, and only for players in a
    current squad.
#}

{% docs nationality %}
The country the player represents, e.g. "England". From wsl_football.
{% enddocs %}

{% docs nationality_iso_code %}
Three-letter country code, e.g. ENG. Not strictly ISO 3166. From wsl_football.
{% enddocs %}

{% docs birth_date %}
Date of birth. From wsl_football, which has no date for a few players.
{% enddocs %}

{% docs height_cm %}
Height in centimetres. The source gives no unit, but its values (153–185) only
fit centimetres. From wsl_football; recorded for about two thirds of players.
{% enddocs %}

{% docs weight_kg %}
Weight in kilograms. The source gives no unit, but its values (40–81) only fit
kilograms. From wsl_football; recorded for about half of players.
{% enddocs %}
