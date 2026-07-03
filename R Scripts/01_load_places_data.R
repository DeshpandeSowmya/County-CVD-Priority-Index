library(tidyverse)
library(janitor)
places_url <- "https://data.cdc.gov/resource/swc5-untb.csv?$limit=200000"
places_raw <- readr::read_csv(
  places_url,
  show_col_types = FALSE,
  col_types = readr::cols(
    data_value_footnote_symbol = readr::col_character(),
    data_value_footnote = readr::col_character(),
    geolocation = readr::col_character()
  )
) |>
  clean_names()
nrow(places_raw)
glimpse(places_raw)
names(places_raw)
count(places_raw, measure, sort = TRUE) |> print(n = 40)
places_selected <- places_raw |>
  filter(
    measure %in% c(
      "Coronary heart disease among adults",
      "Stroke among adults",
      "High blood pressure among adults",
      "Diagnosed diabetes among adults",
      "Obesity among adults",
      "Current cigarette smoking among adults",
      "No leisure-time physical activity among adults"
    ),
    data_value_type == "Age-adjusted prevalence"
  )
count(places_selected, measure, sort = TRUE)
count(places_selected, data_value_type, sort = TRUE)
places_wide <- places_selected |>
  select(
    stateabbr,
    statedesc,
    locationname,
    locationid,
    measure,
    data_value
  ) |>
  pivot_wider(
    names_from = measure,
    values_from = data_value
  ) |>
  clean_names()
glimpse(places_wide)
names(places_wide)
nrow(places_wide)
places_final <- places_wide |>
  rename(
    state_abbr = stateabbr,
    state_name = statedesc,
    county_name = locationname,
    fips = locationid,
    stroke_prev = stroke_among_adults,
    obesity_prev = obesity_among_adults,
    chd_prev = coronary_heart_disease_among_adults,
    high_bp_prev = high_blood_pressure_among_adults,
    diabetes_prev = diagnosed_diabetes_among_adults,
    smoking_prev = current_cigarette_smoking_among_adults,
    inactivity_prev = no_leisure_time_physical_activity_among_adults
  )
glimpse(places_final)
write_csv(places_final, "data_processed/places_county_clean.csv")