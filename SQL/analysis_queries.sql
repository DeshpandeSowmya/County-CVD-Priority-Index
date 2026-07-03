-- Top 10 priority counties
SELECT
  fips,
  state_abbr,
  state_name,
  county_name,
  priority_score,
  priority_rank,
  priority_tier
FROM county_scored
ORDER BY priority_score DESC
LIMIT 10;

-- State average priority score
SELECT
  state_abbr,
  state_name,
  COUNT(*) AS county_count,
  ROUND(AVG(priority_score), 3) AS avg_priority_score
FROM county_scored
GROUP BY state_abbr, state_name
ORDER BY avg_priority_score DESC;

-- Counties with high access-related risk
SELECT
  fips,
  state_abbr,
  state_name,
  county_name,
  uninsured_pct,
  pcp_rate,
  preventable_hospital_stays,
  priority_score,
  priority_tier
FROM county_scored
WHERE uninsured_pct >= (
  SELECT quantile_cont(uninsured_pct, 0.75)
  FROM county_scored
  WHERE uninsured_pct IS NOT NULL
)
  AND preventable_hospital_stays >= (
  SELECT quantile_cont(preventable_hospital_stays, 0.75)
  FROM county_scored
  WHERE preventable_hospital_stays IS NOT NULL
)
ORDER BY priority_score DESC;

-- Top priority county within each state
SELECT *
FROM (
  SELECT
    fips,
    state_abbr,
    state_name,
    county_name,
    priority_score,
    ROW_NUMBER() OVER (
      PARTITION BY state_abbr
      ORDER BY priority_score DESC
    ) AS state_rank
  FROM county_scored
) ranked
WHERE state_rank = 1
ORDER BY priority_score DESC;