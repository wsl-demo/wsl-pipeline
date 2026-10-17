{#
    Column meanings used in three or more places across folders: staging,
    intermediate, marts, or both sources. Each says what the
    value is, wherever it appears. A column's YAML refers to its block and adds
    at most a short qualifier the block can't carry, such as which side of a
    match it belongs to. Blocks whose uses are all inside one folder live in
    that folder's `_[directory]__docs.md`; a meaning used once or twice is
    written inline in the YAML.
#}

{#  IDs  #}

{% docs opta_match_id %}
Opta's match ID, e.g. `1cd4kbemthwb8obzgso3i01lg`.
{% enddocs %}

{% docs opta_player_id %}
Opta's player ID, e.g. `9t8eb24gwj56ucggp7x0n0ewa`: the key BBC Sport and
wsl_football share.
{% enddocs %}

{% docs opta_team_id %}
Opta's team ID, which BBC calls the participant ID, e.g.
`5rurqie3qt1qav9ir5mkqinn` (Arsenal).
{% enddocs %}

{% docs opta_id_from_bbc_id %}
Derived from BBC's ID by the `opta_id_from_bbc_id` macro, which removes the
leading `s-` and returns null for an ID that doesn't start with `s-`.
{% enddocs %}

{#  Time  #}

{% docs season %}
Season label, e.g. "2026-2027". A season runs from 1 July to 30 June; the
`season_of` macro assigns a match to one from the date it was played in the UK.
{% enddocs %}

{% docs match_date %}
The day of the match in the UK. Once there is a result, the day it was
played; before that, the day BBC listed it for.
{% enddocs %}

{% docs kicked_off_at %}
Kickoff, as an absolute timestamp, in UK local time. Null
for a fixture without a result whose time BBC listed as TBC.
{% enddocs %}

{#
    A moment in a match. BBC labels one with the minute being played and any
    added time, e.g. `45'+3`; these three columns split that label and recombine
    it. The source has minutes only, so two things in the same minute cannot be
    put in order.
#}

{% docs regulation_minute %}
The minute being played, without added time: 45 for `45'+3`, 64 for `64'`. Use
it for durations: subtracting two gives the minutes between them with added
time counted as zero length, the same convention as minutes played. The source
doesn't record how long added time lasted, so that is the closest it allows.
{% enddocs %}

{% docs injury_minute %}
The minute of added time: 3 for `45'+3`; 0 outside added time.
{% enddocs %}

{% docs match_minute %}
The moment as one exact decimal, e.g. 45.03 for `45'+3` and 46.00 for `46'`. It
sorts in match order, so use it to order moments and to test whether one falls
between two others. It is not a duration: subtract `regulation_minute` instead.
{% enddocs %}

{#  Matches  #}

{% docs tournament_name %}
Competition name, e.g. "Women's Super League".
{% enddocs %}

{% docs venue_name %}
Stadium name as BBC showed it for the match, e.g. "Joie Stadium". One venue can
appear under more than one name over time. Null for a match without a result,
since fixtures listings do not carry it.
{% enddocs %}

{% docs winner_side %}
`home`, `away` or `draw`. Null for a match without a result.
{% enddocs %}

{% docs score_fulltime %}
Goals the side scored, own goals included. Null for a match without a result.
{% enddocs %}

{% docs points %}
League points the side earned: 3 for a win, 1 for a draw, 0 for a loss. Null
for a match without a result.
{% enddocs %}

{#  Teams  #}

{% docs team_name %}
Full team name as BBC writes it, e.g. "Tottenham Hotspur", without "Women".
{% enddocs %}

{% docs team_short_name %}
Short team name for tight spaces, e.g. "Spurs", "Man Utd".
{% enddocs %}

{% docs team_code %}
Three-letter team code, e.g. "TOT".
{% enddocs %}

{#  A player in a matchday squad  #}

{% docs is_starter %}
True for the starting eleven; false for the bench.
{% enddocs %}

{% docs is_captain %}
True for the team's captain in the match; one per team per match.
{% enddocs %}

{% docs position %}
Playing position, e.g. "Defender". Null for the bench, and so for appearances
made as a substitute.
{% enddocs %}

{% docs shirt_number %}
Shirt number the player wore.
{% enddocs %}

{% docs substituted_off_reason %}
Why the player was taken off: `Tactical` or `Injury`. Null if they weren't.
{% enddocs %}

{% docs substituted_on_reason %}
Why the player this one replaced was taken off: `Tactical` or `Injury`. Null if
this player didn't come on.
{% enddocs %}

{#
    Player names. Both sources provide them; the marts prefer BBC's and fall back
    to wsl_football's.
#}

{% docs name_first %}
The player's first name or names.
{% enddocs %}

{% docs name_last %}
The player's last name.
{% enddocs %}

{% docs display_name %}
The player's name shortened to initial and surname, e.g. "F. Kirby".
{% enddocs %}

{% docs name_shirt %}
The name the player is known by and has printed on the shirt, e.g. "Mapi León".
Recorded for only some players.
{% enddocs %}

{#
    Player biography. Only wsl_football has it, and it lists only current
    squads, so each is null for a player no longer in one.
#}

{% docs nationality %}
The country the player represents, e.g. "England". From wsl_football; null for
a player no longer in a current squad.
{% enddocs %}

{% docs nationality_iso_code %}
Three-letter country code, e.g. ENG. Not strictly ISO 3166. From wsl_football;
null for a player no longer in a current squad.
{% enddocs %}

{% docs birth_date %}
Date of birth. From wsl_football, which has no date for a few players; null for
a player no longer in a current squad.
{% enddocs %}

{% docs height_cm %}
Height in centimetres. The source gives no unit, but its values (153–185) only
fit centimetres. From wsl_football, for about two thirds of players; null for a
player no longer in a current squad.
{% enddocs %}

{% docs weight_kg %}
Weight in kilograms. The source gives no unit, but its values (40–81) only fit
kilograms. From wsl_football, for about half of players; null for a player no
longer in a current squad.
{% enddocs %}
