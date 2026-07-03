library(tidyverse)
library(DBI)
library(duckdb)
county_scored <- readr::read_csv(
  "data_processed/county_scored.csv",
  show_col_types = FALSE,
  col_types = readr::cols(fips = readr::col_character())
)
con <- dbConnect(
  duckdb::duckdb(),
  dbdir = "data_processed/county_health.duckdb",
  read_only = FALSE
)
dbWriteTable(con, "county_scored", county_scored, overwrite = TRUE)
dbListTables(con)
top_10_sql <- dbGetQuery(con, "
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
  LIMIT 10
")
top_10_sql
state_summary_sql <- dbGetQuery(con, "
  SELECT
    state_abbr,
    state_name,
    COUNT(*) AS county_count,
    ROUND(AVG(priority_score), 3) AS avg_priority_score
  FROM county_scored
  GROUP BY state_abbr, state_name
  ORDER BY avg_priority_score DESC
")
state_summary_sql
high_access_risk_sql <- dbGetQuery(con, "
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
  WHERE uninsured_pct >= 10
    AND preventable_hospital_stays >= 2000
  ORDER BY priority_score DESC
")
high_access_risk_sql
top_county_per_state_sql <- dbGetQuery(con, "
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
  ORDER BY priority_score DESC
")
top_county_per_state_sql
write_csv(top_10_sql, "Output/top_10_sql.csv")
write_csv(state_summary_sql, "Output/state_summary_sql.csv")
write_csv(high_access_risk_sql, "Output/high_access_risk_sql.csv")
write_csv(top_county_per_state_sql, "Output/top_county_per_state_sql.csv")
dbGetQuery(con, "
  SELECT
    MIN(uninsured_pct) AS min_uninsured,
    MAX(uninsured_pct) AS max_uninsured,
    AVG(uninsured_pct) AS avg_uninsured,
    MIN(preventable_hospital_stays) AS min_preventable,
    MAX(preventable_hospital_stays) AS max_preventable,
    AVG(preventable_hospital_stays) AS avg_preventable
  FROM county_scored
")
summary(county_scored$uninsured_pct)
summary(county_scored$preventable_hospital_stays)
high_access_risk_sql <- dbGetQuery(con, "
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
  ORDER BY priority_score DESC
")
high_access_risk_sql
write_csv(high_access_risk_sql, "Output/high_access_risk_sql.csv")