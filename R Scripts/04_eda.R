library(tidyverse)
library(janitor)
county_final <- readr::read_csv(
  "data_processed/county_final.csv",
  show_col_types = FALSE,
  col_types = readr::cols(fips = readr::col_character())
) |>
  clean_names()
glimpse(county_final)
nrow(county_final)
names(county_final)
missing_summary <- county_final |>
  summarise(across(everything(), ~ sum(is.na(.)))) |>
  pivot_longer(
    cols = everything(),
    names_to = "variable",
    values_to = "missing_count"
  ) |>
  arrange(desc(missing_count))
missing_summary
summary_stats <- county_final |>
  summarise(
    across(
      c(
        stroke_prev,
        obesity_prev,
        chd_prev,
        high_bp_prev,
        diabetes_prev,
        smoking_prev,
        inactivity_prev,
        uninsured_pct,
        pcp_rate,
        preventable_hospital_stays,
        child_poverty_pct,
        unemployment_pct
      ),
      list(
        mean = ~ mean(., na.rm = TRUE),
        median = ~ median(., na.rm = TRUE),
        min = ~ min(., na.rm = TRUE),
        max = ~ max(., na.rm = TRUE)
      )
    )
  )
summary_stats
county_eda <- county_final |>
  mutate(
    burden_score_simple = (
      stroke_prev +
        obesity_prev +
        chd_prev +
        high_bp_prev +
        diabetes_prev +
        smoking_prev +
        inactivity_prev
    ) / 7
  )
glimpse
top_burden_counties <- county_eda |>
  select(fips, state_abbr, state_name, county_name, burden_score_simple) |>
  arrange(desc(burden_score_simple)) |>
  slice_head(n = 20)
top_burden_counties
corr_data <- county_final |>
  select(
    stroke_prev,
    obesity_prev,
    chd_prev,
    high_bp_prev,
    diabetes_prev,
    smoking_prev,
    inactivity_prev,
    uninsured_pct,
    pcp_rate,
    preventable_hospital_stays,
    child_poverty_pct,
    unemployment_pct
  )
correlation_matrix <- cor(corr_data, use = "pairwise.complete.obs")
correlation_matrix
chd_hist <- ggplot(county_final, aes(x = chd_prev)) +
  geom_histogram(bins = 30, fill = "steelblue", color = "white") +
  labs(
    title = "Distribution of Coronary Heart Disease Prevalence",
    x = "CHD prevalence (%)",
    y = "Number of counties"
  )
chd_hist
ggsave(
  "Output/chd_histogram.png",
  plot = chd_hist,
  width = 8,
  height = 5,
  dpi = 300
)
uninsured_hist <- ggplot(county_final, aes(x = uninsured_pct)) +
  geom_histogram(bins = 30, fill = "darkorange", color = "white") +
  labs(
    title = "Distribution of Uninsured Rate",
    x = "Uninsured (%)",
    y = "Number of counties"
  )
uninsured_hist
ggsave(
  "Output/uninsured_histogram.png",
  plot = uninsured_hist,
  width = 8,
  height = 5,
  dpi = 300
)
smoking_chd_scatter <- ggplot(county_final, aes(x = smoking_prev, y = chd_prev)) +
  geom_point(alpha = 0.5, color = "firebrick") +
  labs(
    title = "Smoking vs Coronary Heart Disease Prevalence",
    x = "Smoking prevalence (%)",
    y = "CHD prevalence (%)"
  )
smoking_chd_scatter
ggsave(
  "Output/smoking_chd_scatter.png",
  plot = smoking_chd_scatter,
  width = 8,
  height = 5,
  dpi = 300
)
write_csv(missing_summary, "Output/missing_summary.csv")
write_csv(top_burden_counties, "Output/top_burden_counties.csv")
write_csv(as.data.frame(correlation_matrix), "Output/correlation_matrix.csv")