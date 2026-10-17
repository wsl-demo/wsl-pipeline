-- Where each starter lined up at kickoff, as a point on a pitch that every
-- formation shares, so starts in different formations can be compared.
--
-- BBC draws the starting eleven as lines of players: row 0 is the goalkeeper
-- and the highest row is the front line. Raw (row, slot) cells don't compare
-- across formations -- row 2 is the holding midfield of a 4-2-3-1 but the whole
-- midfield of a 4-4-2 -- so each is scaled to the formation it belongs to:
--
--   start_depth  row / front row: 0 for the goalkeeper, 1 for the front line.
--   start_width  the middle of the slot's equal share of its line, 0 to 1,
--                with slot 0 at 1 (the right).
--
-- Slot 0 being the right is inferred, not sent: BBC puts formation place 2 in
-- the first slot of its line and place 3 in the last, and Opta numbers the
-- right back 2 and the left back 3. fullbacks_start_on_opposite_flanks fails
-- if BBC's drawing ever stops agreeing.
--
-- The point is where the formation put the player, not where they played.
WITH layout AS (
    SELECT
        l.opta_match_id,
        l.opta_player_id,
        t.opta_team_id,
        {{ season_of(uk_local_date('m.kicked_off_at')) }} AS season,
        t.formation,
        p.formation_place,
        l.row_index,
        l.slot_index,
        COUNT(*) OVER (
            PARTITION BY l.bbc_match_id, l.bbc_team_id, l.row_index
        ) AS row_width,
        MAX(l.row_index) OVER (
            PARTITION BY l.bbc_match_id, l.bbc_team_id
        ) AS outfield_line_count
    FROM {{ ref('stg_bbc_sport__match_pitch_layout') }} AS l
    INNER JOIN {{ ref('stg_bbc_sport__match_teams') }} AS t
        ON l.bbc_match_id = t.bbc_match_id
       AND l.bbc_team_id = t.bbc_team_id
    INNER JOIN {{ ref('stg_bbc_sport__match_players') }} AS p
        ON l.bbc_match_id = p.bbc_match_id
       AND l.bbc_player_id = p.bbc_player_id
    INNER JOIN {{ ref('stg_bbc_sport__matches') }} AS m
        ON l.opta_match_id = m.opta_match_id
)

SELECT
    opta_match_id,
    opta_player_id,
    opta_team_id,
    season,
    formation,
    formation_place,
    row_index,
    slot_index,
    row_width,
    outfield_line_count,
    -- Three decimal places: exact for every point a formation can produce at
    -- this scale except the thirds, and equal points compare equal downstream.
    CAST(CAST(row_index AS double) / outfield_line_count AS decimal(4, 3))
        AS start_depth,
    CAST(1 - (CAST(slot_index AS double) + 0.5) / row_width AS decimal(4, 3))
        AS start_width
FROM layout
