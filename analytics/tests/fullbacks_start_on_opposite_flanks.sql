-- start_width puts slot 0 on the right. Nothing BBC sends says so: it rests on
-- Opta numbering the right back (or right wing-back) 2 and the left back 3, and
-- on BBC drawing place 2 in the first slot of its line and place 3 in the last.
-- A row here means the drawing no longer agrees, and every start_width may be
-- mirrored.
SELECT
    opta_match_id,
    opta_player_id,
    formation,
    formation_place,
    row_index,
    slot_index,
    row_width
FROM {{ ref('int_players_start_location_derived') }}
WHERE (formation_place = 2 AND slot_index <> 0)
   OR (formation_place = 3 AND slot_index <> row_width - 1)
