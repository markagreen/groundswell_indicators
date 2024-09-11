# 1. Setup ----
# set location for outputs
data_dir <- Sys.getenv("GW_RDD") |>
  file.path("UPRN/Flood risk indicator")

# 2. Data Quality assessment ----
# create temporary file
tmp_file <- tempfile(fileext = ".zip")
# download latest OS Open UPRN dataset
oopt <- options(timeout = 120)
download.file(
  url = "https://api.os.uk/downloads/v1/products/OpenUPRN/downloads?area=GB&format=CSV&redirect",
  destfile = tmp_file
)
options(oopt)
# extract data
unzip(tmp_file, exdir = dirname(tmp_file))
files <-
  list.files(dirname(tmp_file), pattern = "osopenuprn", full.names = TRUE)

# load the OS Open UPRN dataset
osopenuprn <- files[length(files)] |> # read the latest version
  readr::read_csv()

# load the output with the flood risk indicator
flood_risk <-
  file.path(data_dir, "uprn_flood_risk.csv") |>
  readr::read_csv()
# tidy up the data
flood_risk_v2 <- flood_risk |>
  dplyr::select(-1) |> # drop rown numbers
  magrittr::set_names( # update column names
    c(
      "UPRN",
      "surface_flood_risk",
      "rivers_sea_flood_risk_high",
      "rivers_sea_flood_risk_medium",
      "rivers_sea_flood_risk_low",
      "rivers_sea_flood_risk_very_low"
    )
  ) |>
  dplyr::distinct() # drop duplicated rows

# drop 'deprecated' UPRNS (i.e., UPRNs not in the OS Open UPRN dataset)
flood_risk_v3 <- flood_risk_v2 |>
  dplyr::left_join(
    osopenuprn |>
      dplyr::select(UPRN, latitude = LATITUDE, longitude = LONGITUDE),
    by = "UPRN"
  ) |>
  dplyr::filter(!is.na(latitude), !is.na(longitude))

# store the new version of the data set
## without coordinates
flood_risk_v3 |>
  dplyr::select(-latitude, -longitude) |>
  readr::write_excel_csv(file.path(data_dir, "UPRN_1_1_flood_risk.csv"))
## with coordinates
flood_risk_v3 |>
  readr::write_excel_csv(file.path(data_dir, "UPRN_1_1_flood_risk_with_coords.csv"))

# remove intermediate files
unlink(tmp_file)

# 3. Visualisations ----
# re-load indicator (in case only the visualisations are executed)
flood_risk_v3 <- file.path(data_dir, "UPRN_1_1_flood_risk_with_coords.csv") |>
  readr::read_csv()

# create spatial object for the metric
flood_risk_v3_sf <- flood_risk_v3 |>
  dplyr::mutate(
    surface_flood_risk = as.factor(surface_flood_risk),
    rivers_sea_flood_risk_high = as.factor(rivers_sea_flood_risk_high),
    rivers_sea_flood_risk_medium = as.factor(rivers_sea_flood_risk_medium),
    rivers_sea_flood_risk_low = as.factor(rivers_sea_flood_risk_low),
    rivers_sea_flood_risk_very_low = as.factor(rivers_sea_flood_risk_very_low)
  ) |>
  sf::st_as_sf(coords = c("longitude", "latitude"), crs = 4326)

# load reference LAs divisions
### source: https://geoportal.statistics.gov.uk/datasets/34cae3dd946847f78b6dfc6bd5add3c7_0/
uk_counties <-
  file.path(Sys.getenv("DATA_DIR"),
            "Counties_and_Unitary_Authorities_May_2023_UK_BFC.gpkg") |>
  sf::read_sf() |>
  janitor::clean_names() |>
  dplyr::filter(
    ctyua23nm %in% c(
      "Cheshire East",
      "Cheshire West and Chester",
      "Halton",
      "Knowsley",
      "Liverpool",
      "Sefton",
      "St. Helens",
      "Warrington",
      "Wirral"
    )
  )

### surface_flood_risk ----
flood_risk_v3_sf |>
  dplyr::arrange(surface_flood_risk) |>
  dplyr::mutate(surface_flood_risk = surface_flood_risk |>
                  forcats::fct_recode("Yes" = "1", "No" = "0")) |>
  ggplot2::ggplot() +
  ggplot2::geom_sf(ggplot2::aes(fill = surface_flood_risk),
                   stroke = 0.01,
                   size = 0.75,
                   shape = 21) +
  ggplot2::geom_sf(data = uk_counties, fill = NA) +
  ggplot2::scale_fill_manual(
    "At risk?",
    values = c("No" = "#D6EAF8", "Yes" = "#138D75")
  ) +
  ggplot2::labs(
    title = "UPRN level flood risk indicator",
    subtitle = "Surface flood risk",
    x = "Longitude",
    y = "Latitude"
  ) +
  ggplot2::theme_bw() +
  ggplot2::guides(
    fill = ggplot2::guide_legend(override.aes = list(size = 3, stroke = .5))
  )

ggplot2::ggsave(
  filename = file.path(data_dir, "UPRN_1_1_flood_risk_surface_flood_risk.png"),
  width = 12,
  height = 11,
  dpi = 300
)

### rivers_sea_flood_risk_high ----
flood_risk_v3_sf |>
  dplyr::arrange(rivers_sea_flood_risk_high) |>
  dplyr::mutate(rivers_sea_flood_risk_high = rivers_sea_flood_risk_high |>
                  forcats::fct_recode("Yes" = "1", "No" = "0")) |>
  ggplot2::ggplot() +
  ggplot2::geom_sf(ggplot2::aes(fill = rivers_sea_flood_risk_high),
                   stroke = 0.01,
                   size = 0.75,
                   shape = 21) +
  ggplot2::geom_sf(data = uk_counties, fill = NA) +
  ggplot2::scale_fill_manual(
    "At risk?",
    values = c("No" = "#D6EAF8", "Yes" = "#138D75")
  ) +
  ggplot2::labs(
    title = "UPRN level flood risk indicator",
    subtitle = "Rivers & Sea flood risk 'High'",
    x = "Longitude",
    y = "Latitude"
  ) +
  ggplot2::theme_bw() +
  ggplot2::guides(
    fill = ggplot2::guide_legend(override.aes = list(size = 3, stroke = .5))
  )

ggplot2::ggsave(
  filename = file.path(data_dir, "UPRN_1_1_flood_risk_rivers_sea_flood_risk_high.png"),
  width = 12,
  height = 11,
  dpi = 300
)

### rivers_sea_flood_risk_medium ----
flood_risk_v3_sf |>
  dplyr::arrange(rivers_sea_flood_risk_medium) |>
  dplyr::mutate(rivers_sea_flood_risk_medium = rivers_sea_flood_risk_medium |>
                  forcats::fct_recode("Yes" = "1", "No" = "0")) |>
  ggplot2::ggplot() +
  ggplot2::geom_sf(ggplot2::aes(fill = rivers_sea_flood_risk_medium),
                   stroke = 0.01,
                   size = 0.75,
                   shape = 21) +
  ggplot2::geom_sf(data = uk_counties, fill = NA) +
  ggplot2::scale_fill_manual(
    "At risk?",
    values = c("No" = "#D6EAF8", "Yes" = "#138D75")
  ) +
  ggplot2::labs(
    title = "UPRN level flood risk indicator",
    subtitle = "Rivers & Sea flood risk 'Medium'",
    x = "Longitude",
    y = "Latitude"
  ) +
  ggplot2::theme_bw() +
  ggplot2::guides(
    fill = ggplot2::guide_legend(override.aes = list(size = 3, stroke = .5))
  )

ggplot2::ggsave(
  filename = file.path(data_dir, "UPRN_1_1_flood_risk_rivers_sea_flood_risk_medium.png"),
  width = 12,
  height = 11,
  dpi = 300
)

### rivers_sea_flood_risk_low ----
flood_risk_v3_sf |>
  dplyr::arrange(rivers_sea_flood_risk_low) |>
  dplyr::mutate(rivers_sea_flood_risk_low = rivers_sea_flood_risk_low |>
                  forcats::fct_recode("Yes" = "1", "No" = "0")) |>
  ggplot2::ggplot() +
  ggplot2::geom_sf(ggplot2::aes(fill = rivers_sea_flood_risk_low),
                   stroke = 0.01,
                   size = 0.75,
                   shape = 21) +
  ggplot2::geom_sf(data = uk_counties, fill = NA) +
  ggplot2::scale_fill_manual(
    "At risk?",
    values = c("No" = "#D6EAF8", "Yes" = "#138D75")
  ) +
  ggplot2::labs(
    title = "UPRN level flood risk indicator",
    subtitle = "Rivers & Sea flood risk 'Low'",
    x = "Longitude",
    y = "Latitude"
  ) +
  ggplot2::theme_bw() +
  ggplot2::guides(
    fill = ggplot2::guide_legend(override.aes = list(size = 3, stroke = .5))
  )

ggplot2::ggsave(
  filename = file.path(data_dir, "UPRN_1_1_flood_risk_rivers_sea_flood_risk_low.png"),
  width = 12,
  height = 11,
  dpi = 300
)

### rivers_sea_flood_risk_very_low ----
flood_risk_v3_sf |>
  dplyr::arrange(rivers_sea_flood_risk_very_low) |>
  dplyr::mutate(rivers_sea_flood_risk_very_low = rivers_sea_flood_risk_very_low |>
                  forcats::fct_recode("Yes" = "1", "No" = "0")) |>
  ggplot2::ggplot() +
  ggplot2::geom_sf(ggplot2::aes(fill = rivers_sea_flood_risk_very_low),
                   stroke = 0.01,
                   size = 0.75,
                   shape = 21) +
  ggplot2::geom_sf(data = uk_counties, fill = NA) +
  ggplot2::scale_fill_manual(
    "At risk?",
    values = c("No" = "#D6EAF8", "Yes" = "#138D75")
  ) +
  ggplot2::labs(
    title = "UPRN level flood risk indicator",
    subtitle = "Rivers & Sea flood risk 'Very low'",
    x = "Longitude",
    y = "Latitude"
  ) +
  ggplot2::theme_bw() +
  ggplot2::guides(
    fill = ggplot2::guide_legend(override.aes = list(size = 3, stroke = .5))
  )

ggplot2::ggsave(
  filename = file.path(data_dir, "UPRN_1_1_flood_risk_rivers_sea_flood_risk_very_low.png"),
  width = 12,
  height = 11,
  dpi = 300
)
