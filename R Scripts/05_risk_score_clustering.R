library(tidyverse)
library(janitor)
county_final <- readr::read_csv(
  "data_processed/county_final.csv",
  show_col_types = FALSE,
  col_types = readr::cols(fips = readr::col_character())
) |>
  clean_names()
glimpse(county_final)
county_scored <- county_final |>
  mutate(
    z_stroke = as.numeric(scale(stroke_prev)),
    z_obesity = as.numeric(scale(obesity_prev)),
    z_chd = as.numeric(scale(chd_prev)),
    z_high_bp = as.numeric(scale(high_bp_prev)),
    z_diabetes = as.numeric(scale(diabetes_prev)),
    z_smoking = as.numeric(scale(smoking_prev)),
    z_inactivity = as.numeric(scale(inactivity_prev)),
    z_uninsured = as.numeric(scale(uninsured_pct)),
    z_pcp_rate_reversed = -as.numeric(scale(pcp_rate)),
    z_preventable_hosp = as.numeric(scale(preventable_hospital_stays)),
    z_child_poverty = as.numeric(scale(child_poverty_pct)),
    z_unemployment = as.numeric(scale(unemployment_pct))
  ) |>
  mutate(
    burden_score = rowMeans(
      cbind(
        z_stroke,
        z_obesity,
        z_chd,
        z_high_bp,
        z_diabetes,
        z_smoking,
        z_inactivity
      ),
      na.rm = TRUE
    ),
    access_score = rowMeans(
      cbind(
        z_uninsured,
        z_pcp_rate_reversed,
        z_preventable_hosp
      ),
      na.rm = TRUE
    ),
    social_score = rowMeans(
      cbind(
        z_child_poverty,
        z_unemployment
      ),
      na.rm = TRUE
    )
  ) |>
  mutate(
    priority_score = 0.5 * burden_score +
      0.3 * access_score +
      0.2 * social_score
  ) |>
  mutate(
    priority_rank = min_rank(desc(priority_score)),
    priority_quartile = ntile(desc(priority_score), 4),
    priority_tier = case_when(
      priority_quartile == 1 ~ "Very High",
      priority_quartile == 2 ~ "High",
      priority_quartile == 3 ~ "Moderate",
      priority_quartile == 4 ~ "Lower"
    )
  )
glimpse(county_scored)
summary(county_scored$priority_score)
top_priority_counties <- county_scored |>
  select(
    fips,
    state_abbr,
    state_name,
    county_name,
    burden_score,
    access_score,
    social_score,
    priority_score,
    priority_rank,
    priority_tier
  ) |>
  arrange(priority_rank) |>
  slice_head(n = 25)
top_priority_counties
cluster_input <- county_scored |>
  select(
    fips,
    state_abbr,
    state_name,
    county_name,
    burden_score,
    access_score,
    social_score,
    priority_score
  ) |>
  drop_na(burden_score, access_score, social_score)
set.seed(123)
kmeans_result <- kmeans(
  cluster_input |>
    select(burden_score, access_score, social_score),
  centers = 4,
  nstart = 25
)
clustered_counties <- cluster_input |>
  mutate(
    cluster = factor(kmeans_result$cluster)
  )
cluster_summary <- clustered_counties |>
  group_by(cluster) |>
  summarise(
    counties = n(),
    avg_burden_score = mean(burden_score, na.rm = TRUE),
    avg_access_score = mean(access_score, na.rm = TRUE),
    avg_social_score = mean(social_score, na.rm = TRUE),
    avg_priority_score = mean(priority_score, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(avg_priority_score))
cluster_summary
county_scored <- county_scored |>
  left_join(
    clustered_counties |>
      select(fips, cluster),
    by = "fips"
  )
glimpse(county_scored)
count(county_scored, cluster)
write_csv(county_scored, "data_processed/county_scored.csv")
write_csv(top_priority_counties, "Output/top_priority_counties.csv")
write_csv(cluster_summary, "Output/cluster_summary.csv")
top_priority_counties |> print(n = 25)
cluster_summary |> print(n = 4)