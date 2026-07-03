library(tidyverse)
library(janitor)
places <- readr::read_csv(
  "data_processed/places_county_clean.csv",
  show_col_types = FALSE,
  col_types = readr::cols(fips = readr::col_character())
) |>
  clean_names()
chr <- readr::read_csv(
  "data_processed/chr_county_clean.csv",
  show_col_types = FALSE,
  col_types = readr::cols(fips = readr::col_character())
) |>
  clean_names()
glimpse(places)
glimpse(chr)
nrow(places)
nrow(chr)
count(places, fips)
count(chr, fips)
places |>
  count(fips) |>
  filter(n > 1)
chr |>
  count(fips) |>
  filter(n > 1)
county_merged <- places |>
  left_join(
    chr,
    by = "fips",
    relationship = "one-to-one"
  )
glimpse(county_merged)
nrow(county_merged)
names(county_merged)
sum(is.na(county_merged$uninsured_pct))
sum(is.na(county_merged$pcp_rate))
sum(is.na(county_merged$preventable_hospital_stays))
sum(is.na(county_merged$child_poverty_pct))
sum(is.na(county_merged$unemployment_pct))
write_csv(county_merged, "data_processed/county_merged.csv")
county_final <- county_merged |>
  transmute(
    fips,
    state_abbr = state_abbr.x,
    state_name,
    county_name = county_name.x,
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
glimpse(county_final)
nrow(county_final)
names(county_final)
write_csv(county_final, "data_processed/county_final.csv")