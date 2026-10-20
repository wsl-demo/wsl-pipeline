{#
    Column meanings used in three or more places, all within BBC Sport's
    sources and staging models. A raw column and the staging column built from
    it share a block when they mean the same thing; the `raw_*` blocks are for
    raw values whose form staging changes, such as URNs.
#}

{#  IDs  #}

{% docs bbc_match_id %}
BBC's internal match ID: `s-` followed by Opta's match ID, e.g. `s-1cd4kbemthwb8obzgso3i01lg`.
Stable whether or not the match is a future fixture.
{% enddocs %}

{% docs bbc_player_id %}
BBC's internal player ID: `s-` followed by Opta's player ID, e.g. `s-9t8eb24gwj56ucggp7x0n0ewa`.
{% enddocs %}

{% docs bbc_team_id %}
BBC's internal team ID: a slug such as `arsenal-ladies` or `manchester-city-women`.
Unlike BBC's match and player IDs, it does not contain Opta's ID, so Opta's
team ID cannot be derived from it.
{% enddocs %}

{% docs bbc_match_page_id %}
BBC's match page slug, as in the page's URL, e.g. `c04xwd27dr2t`: the page about
the match, not the match. Matches have one only from the 2023-24 season. BBC
can make it days before kickoff: two matches on 24 October 2026 had one by
20 October.
{% enddocs %}

{% docs opta_tournament_id %}
Opta's competition ID, `6vq8j5p3av14nr3iuyi4okhjt` for the WSL.
{% enddocs %}

{#  Raw URNs. Staging removes the prefix, leaving BBC's ID.  #}

{% docs raw_match_urn %}
BBC's match URN: `urn:bbc:sportsdata:football:event:` followed by BBC's match
ID, e.g. `urn:bbc:sportsdata:football:event:s-1cd4kbemthwb8obzgso3i01lg`.
{% enddocs %}

{% docs raw_team_urn %}
BBC's team URN: `urn:bbc:sportsdata:football:team:` followed by BBC's team ID,
e.g. `urn:bbc:sportsdata:football:team:arsenal-ladies`.
{% enddocs %}

{% docs raw_player_urn %}
BBC's player URN: `urn:bbc:sportsdata:football:player:` followed by BBC's player
ID, e.g. `urn:bbc:sportsdata:football:player:s-9t8eb24gwj56ucggp7x0n0ewa`.
{% enddocs %}

{#  Matches  #}

{% docs score_halftime %}
Goals the side had scored at half-time, own goals included.
{% enddocs %}

{% docs alignment %}
Which side the team played as: `home` or `away`.
{% enddocs %}

{% docs source_side %}
Which side the team played as: `homeTeam` or `awayTeam`.
{% enddocs %}

{#  Statistics  #}

{% docs stat_value %}
The statistic's value, e.g. `90` or `87.5`. Every statistic is numeric;
percentages run from 0 to 100.
{% enddocs %}
