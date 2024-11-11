# 1. Setup ----
# set location for outputs
data_dir <- Sys.getenv("GW_RDD") |>
  file.path("UPRN/Satellite measures")

# 2. Data Quality assessment ----
# create temporary file
tmp_file <- tempfile(fileext = ".zip")
# download latest OS Open UPRN dataset
oopt <- options(timeout = 500)
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

# load the output with the satellite measures
## summer 2024
satellite_measures <-
  file.path(data_dir, "uprn_satellite_measures.csv") |>
  readr::read_csv()
# tidy up the data
satellite_measures_v2 <- satellite_measures |>
  dplyr::select(-1) |> # drop rown numbers
  magrittr::set_names( # update column names
    c(
      "TOID",
      "lad23cd",
      "UPRN",
      "easting",
      "northing",
      "EVI",
      "NDVI",
      "NDWI"
    )
  ) |>
  # drop additional rows
  dplyr::select(-TOID, -lad23cd, -easting, -northing) |>
  dplyr::distinct() # drop duplicated rows

# drop 'deprecated' UPRNS (i.e., UPRNs not in the OS Open UPRN dataset)
satellite_measures_v3 <- satellite_measures_v2 |>
  dplyr::left_join(
    osopenuprn |>
      dplyr::select(UPRN, latitude = LATITUDE, longitude = LONGITUDE),
    by = "UPRN"
  ) |>
  dplyr::filter(!is.na(latitude), !is.na(longitude))

# UPRNs without values
satellite_measures_v3 |>
  dplyr::filter(is.na(EVI)) |>
  leaflet::leaflet() |>
  leaflet::addProviderTiles("CartoDB.Positron") |>
  leaflet::addCircles()

# create clean version of the metric
satellite_measures_v4 <- satellite_measures_v3 |>
  dplyr::filter(!is.na(EVI), !is.na(NDVI), !is.na(NDWI)) |>
  dplyr::rename(
    EVI_2024 = EVI,
    NDVI_2024 = NDVI,
    NDWI_2024 = NDWI
  )
# store the new version of the data set
## without coordinates
satellite_measures_v4 |>
  dplyr::select(-latitude, -longitude) |>
  readr::write_excel_csv(file.path(data_dir, "UPRN_5_1_satellite_measures_cm.csv"))
## with coordinates
satellite_measures_v4 |>
  readr::write_excel_csv(file.path(data_dir, "UPRN_5_1_satellite_measures_cm_with_coords.csv"))

# remove intermediate files
unlink(tmp_file)

# 3. Visualisations ----
# re-load indicator (in case only the visualisations are executed)
satellite_measures_v4 <- file.path(data_dir, "UPRN_5_1_satellite_measures_with_coords.csv") |>
  readr::read_csv()

# create spatial object for the metric
satellite_measures_v4_sf <- satellite_measures_v4 |>
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

### EVI ----
satellite_measures_v4_sf |>
  dplyr::arrange(EVI_2024) |>
  ggplot2::ggplot() +
  ggplot2::geom_sf(ggplot2::aes(fill = EVI_2024),
                   stroke = 0.01,
                   size = 0.75,
                   shape = 21) +
  ggplot2::scale_fill_gradient2("EVI [-]", limits = c(-1, 1),
                                low = "#7a0000",
                                high = "#325B89") +
  ggplot2::labs(
    title = "UPRN level satellite measures",
    subtitle = "Enhanced Vegetation Index (EVI)",
    x = "Longitude",
    y = "Latitude"
  ) +
  ggplot2::geom_sf(data = uk_counties, fill = NA) +
  ggplot2::theme_dark() +
  ggplot2::guides(
    fill = ggplot2::guide_colourbar(
      position = "bottom",
      theme = ggplot2::theme(
        legend.key.width  = ggplot2::unit(30, "lines"),
        legend.key.height = ggplot2::unit(2, "lines")
      )
    )
  )

ggplot2::ggsave(
  filename = file.path(data_dir, "UPRN_5_1_satellite_measures_cm_EVI_2024.png"),
  width = 12,
  height = 13,
  dpi = 300
)

#### Negative ----
pal <- leaflet::colorNumeric(c("#7a0000", "#FFFFFF", "#325B89"), domain = c(-1, 1))
satellite_measures_v4_sf |>
  dplyr::arrange(dplyr::desc(EVI_2024)) |>
  dplyr::filter(EVI_2024 <= 0) |>
  leaflet::leaflet() |>
  leaflet::addProviderTiles("CartoDB.Positron") |>
  leaflet::addCircleMarkers(
    fillColor = ~pal(EVI_2024),
    fillOpacity = 1,
    radius = 3,
    weight = 1,
    color = "#000000"
  )

### NDVI ----
satellite_measures_v4_sf |>
  dplyr::arrange(NDVI_2024) |>
  ggplot2::ggplot() +
  ggplot2::geom_sf(ggplot2::aes(fill = NDVI_2024),
                   stroke = 0.01,
                   size = 0.75,
                   shape = 21) +
  ggplot2::geom_sf(data = uk_counties, fill = NA) +
  ggplot2::scale_fill_gradient2("NDVI [-]", limits = c(-1, 1),
                                low = "#7a0000",
                                high = "#325B89") +
  ggplot2::labs(
    title = "UPRN level satellite measures",
    subtitle = "Normalised Difference Vegetation Index (NDVI)",
    x = "Longitude",
    y = "Latitude"
  ) +
  ggplot2::theme_dark() +
  ggplot2::guides(
    fill = ggplot2::guide_colourbar(
      position = "bottom",
      theme = ggplot2::theme(
        legend.key.width  = ggplot2::unit(30, "lines"),
        legend.key.height = ggplot2::unit(2, "lines")
      )
    )
  )

ggplot2::ggsave(
  filename = file.path(data_dir, "UPRN_5_1_satellite_measures_cm_NDVI_2024.png"),
  width = 12,
  height = 13,
  dpi = 300
)

#### Negative ----
pal <- leaflet::colorNumeric(c("#7a0000", "#FFFFFF", "#325B89"), domain = c(-1, 1))
satellite_measures_v4_sf |>
  dplyr::arrange(dplyr::desc(NDVI_2024)) |>
  dplyr::filter(NDVI_2024 <= 0) |>
  leaflet::leaflet() |>
  leaflet::addProviderTiles("CartoDB.Positron") |>
  leaflet::addCircleMarkers(
    fillColor = ~pal(NDVI_2024),
    fillOpacity = 1,
    radius = 3,
    weight = 1,
    color = "#000000"
  )

### NDWI ----
satellite_measures_v4_sf |>
  dplyr::arrange(NDWI_2024) |>
  ggplot2::ggplot() +
  ggplot2::geom_sf(ggplot2::aes(fill = NDWI_2024),
                   stroke = 0.01,
                   size = 0.75,
                   shape = 21) +
  ggplot2::geom_sf(data = uk_counties, fill = NA) +
  ggplot2::scale_fill_gradient2("NDWI [-]", limits = c(-1, 1),
                                low = "#7a0000",
                                high = "#325B89") +
  ggplot2::labs(
    title = "UPRN level satellite measures",
    subtitle = "Normalised Difference Water Index (NDWI)",
    x = "Longitude",
    y = "Latitude"
  ) +
  ggplot2::theme_dark() +
  ggplot2::guides(
    fill = ggplot2::guide_colourbar(
      position = "bottom",
      theme = ggplot2::theme(
        legend.key.width  = ggplot2::unit(30, "lines"),
        legend.key.height = ggplot2::unit(2, "lines")
      )
    )
  )

ggplot2::ggsave(
  filename = file.path(data_dir, "UPRN_5_1_satellite_measures_cm_NDWI_2024.png"),
  width = 12,
  height = 13,
  dpi = 300
)

#### Positive ----
pal <- leaflet::colorNumeric(c("#7a0000", "#FFFFFF", "#325B89"), domain = c(-1, 1))
satellite_measures_v4_sf |>
  dplyr::arrange(dplyr::desc(NDWI_2024)) |>
  dplyr::filter(NDWI_2024 >= 0) |>
  leaflet::leaflet() |>
  leaflet::addProviderTiles("CartoDB.Positron") |>
  leaflet::addCircleMarkers(
    fillColor = ~pal(NDWI_2024),
    fillOpacity = 1,
    radius = 3,
    weight = 1,
    color = "#000000"
  )
