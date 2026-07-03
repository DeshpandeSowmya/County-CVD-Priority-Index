library(tidyverse)
library(janitor)
chr_url <- "https://www.countyhealthrankings.org/sites/default/files/media/document/analytic_data2025_v3.csv"
chr_raw_file <- "data_raw/chr_2025_analytic_data.csv"
download.file(
  url = chr_url,
  destfile = chr_raw_file,
  mode = "wb"
)
chr_raw <- readr::read_csv(chr_raw_file, show_col_types = FALSE) |>
  clean_names()
nrow(chr_raw)
glimpse(chr_raw)
names(chr_raw)
chr_selected <- chr_raw |>
  filter(
    !is.na(x5_digit_fips_code),
    x5_digit_fips_code != "",
    county_fips_code != "000",
    state_abbreviation != "US"
  ) |>
  transmute(
    fips = x5_digit_fips_code,
    state_abbr = state_abbreviation,
    county_name = name,
    uninsured_pct = readr::parse_number(uninsured_raw_value),
    pcp_rate = readr::parse_number(primary_care_physicians_raw_value),
    preventable_hospital_stays = readr::parse_number(preventable_hospital_stays_raw_value),
    child_poverty_pct = readr::parse_number(children_in_poverty_raw_value),
    unemployment_pct = readr::parse_number(unemployment_raw_value)
  ) |>
  distinct(fips, .keep_all = TRUE)
glimpse(chr_selected)
nrow(chr_selected)
names(chr_selected)
write_csv(chr_selected, "data_processed/chr_county_clean.csv")