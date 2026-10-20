-- A finished match is described twice: by BBC's listing and by its own page.
-- They must name the same teams the same way round, the same kickoff, the same
-- full-time score and the same winner, or one of the two is mis-parsed. A stale
-- page cannot explain a difference for long: the scraper fetches a page again
-- as soon as its listing's result changes.
SELECT
    listed.opta_match_id,
    listed.kicked_off_at AS listed_kicked_off_at,
    page.kicked_off_at AS page_kicked_off_at,
    listed.home_score_fulltime AS listed_home_score,
    page.home_score_fulltime AS page_home_score,
    listed.away_score_fulltime AS listed_away_score,
    page.away_score_fulltime AS page_away_score,
    listed.winner_side AS listed_winner,
    page.winner_side AS page_winner
FROM {{ ref('int_matches_listing_state_derived') }} AS listed
INNER JOIN {{ ref('stg_bbc_sport__matches') }} AS page
    ON listed.opta_match_id = page.opta_match_id
WHERE listed.bbc_status = 'PostEvent'
  AND (
      listed.opta_home_team_id <> page.opta_home_team_id
      OR listed.opta_away_team_id <> page.opta_away_team_id
      OR listed.kicked_off_at IS DISTINCT FROM page.kicked_off_at
      OR listed.home_score_fulltime IS DISTINCT FROM page.home_score_fulltime
      OR listed.away_score_fulltime IS DISTINCT FROM page.away_score_fulltime
      OR listed.winner_side IS DISTINCT FROM page.winner_side
  )
