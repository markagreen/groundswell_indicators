# 1. Setup ----
# set location for outputs
data_dir <- Sys.getenv("GW_RDD") |>
  file.path("UPRN")

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

## 2.1. greenspace distances ----
# load the output with the green spaces distances
greenspace_distances <-
  file.path(data_dir, "distance to nearest green space mag/uprn_greenspace_distances.csv") |>
  readr::read_csv()
# tidy up the data
greenspace_distances_v2 <- greenspace_distances |>
  dplyr::select(-1) |> # drop rown numbers
  magrittr::set_names( # update column names
    c(
      "TOID",
      "UPRN",
      "lad23cd",
      "distance_any_greenspace",
      "distance_doorstop_greenspace",
      "distance_local_greenspace",
      "distance_neighbourhood_greenspace",
      "distance_wider_greenspace",
      "distance_district_greenspace",
      "distance_subregional_greenspace"
    )
  ) |>
  dplyr::select(-TOID, -lad23cd) |>
  dplyr::arrange(UPRN) |>
  dplyr::distinct() # drop duplicated rows

# drop 'deprecated' UPRNS (i.e., UPRNs not in the OS Open UPRN dataset)
greenspace_distances_v3 <- greenspace_distances_v2 |>
  dplyr::left_join(
    osopenuprn |>
      dplyr::select(UPRN, latitude = LATITUDE, longitude = LONGITUDE),
    by = "UPRN"
  ) |>
  dplyr::filter(!is.na(latitude), !is.na(longitude))

# store the new version of the data set
## without coordinates
greenspace_distances_v3 |>
  dplyr::select(-latitude, -longitude) |>
  readr::write_excel_csv(file.path(data_dir, "distance to nearest green space mag/UPRN_2_1_greenspace_distances.csv"))
## with coordinates
greenspace_distances_v3 |>
  readr::write_excel_csv(file.path(data_dir, "distance to nearest green space mag/UPRN_2_1_greenspace_distances_with_coords.csv"))

## 2.2. bluespace distances ----
# load the output with the blue spaces distances
bluespace_distances <-
  file.path(data_dir, "Blue space indicators/uprn_bluespace_distances.csv") |>
  readr::read_csv()
# tidy up the data
bluespace_distances_v2 <- bluespace_distances |>
  dplyr::select(-1) |> # drop rown numbers
  magrittr::set_names( # update column names
    c(
      "TOID",
      "UPRN",
      "lad23cd",
      "distance_any_bluespace"
    )
  ) |>
  dplyr::select(-TOID, -lad23cd) |>
  dplyr::arrange(UPRN) |>
  dplyr::distinct() # drop duplicated rows

# drop 'deprecated' UPRNS (i.e., UPRNs not in the OS Open UPRN dataset)
bluespace_distances_v3 <- bluespace_distances_v2 |>
  dplyr::left_join(
    osopenuprn |>
      dplyr::select(UPRN, latitude = LATITUDE, longitude = LONGITUDE),
    by = "UPRN"
  ) |>
  dplyr::filter(!is.na(latitude), !is.na(longitude))

# store the new version of the data set
## without coordinates
bluespace_distances_v3 |>
  dplyr::select(-latitude, -longitude) |>
  readr::write_excel_csv(file.path(data_dir, "Blue space indicators/UPRN_4_1_bluespace_distances.csv"))
## with coordinates
bluespace_distances_v3 |>
  readr::write_excel_csv(file.path(data_dir, "Blue space indicators/UPRN_4_1_bluespace_distances_with_coords.csv"))

# remove intermediate files
unlink(tmp_file)

# 3. Visualisations ----
## 3.1. greenspace distances ----
# re-load indicator (in case only the visualisations are executed)
greenspace_distances_v3 <- file.path(data_dir, "distance to nearest green space mag/UPRN_2_1_greenspace_distances_with_coords.csv") |>
  readr::read_csv()

# create spatial object for the metric
greenspace_distances_v3_sf <- greenspace_distances_v3 |>
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

### distance_any_greenspace ----
greenspace_distances_v3_sf |>
  dplyr::arrange(distance_any_greenspace) |>
  ggplot2::ggplot() +
  ggplot2::geom_sf(ggplot2::aes(fill = distance_any_greenspace),
                   stroke = 0.01,
                   size = 0.75,
                   shape = 21) +
  ggplot2::geom_sf(data = uk_counties, fill = NA) +
  ggplot2::scale_fill_distiller(
    palette = "Spectral",
    breaks = scales::breaks_pretty(9)
  ) +
  ggplot2::labs(
    title = "UPRN level greenspace access indicator",
    subtitle = "Distance to any greenspace",
    fill = "Distance [m]",
    x = "Longitude",
    y = "Latitude"
  ) +
  ggplot2::theme_bw() +
  ggplot2::guides(
    fill = ggplot2::guide_legend(override.aes = list(size = 3, stroke = .5))
  )

ggplot2::ggsave(
  filename = file.path(data_dir, "distance to nearest green space mag/UPRN_2_1_greenspace_distances_any_greenspace.png"),
  width = 12,
  height = 11,
  dpi = 300
)

### distance_doorstop_greenspace ----
greenspace_distances_v3_sf |>
  dplyr::arrange(distance_doorstop_greenspace) |>
  ggplot2::ggplot() +
  ggplot2::geom_sf(ggplot2::aes(fill = distance_doorstop_greenspace),
                   stroke = 0.01,
                   size = 0.75,
                   shape = 21) +
  ggplot2::geom_sf(data = uk_counties, fill = NA) +
  ggplot2::scale_fill_distiller(
    palette = "Spectral",
    breaks = scales::breaks_pretty(9)
  ) +
  ggplot2::labs(
    title = "UPRN level greenspace access indicator",
    subtitle = "Distance to doorstep greenspace",
    fill = "Distance [m]",
    x = "Longitude",
    y = "Latitude"
  ) +
  ggplot2::theme_bw() +
  ggplot2::guides(
    fill = ggplot2::guide_legend(override.aes = list(size = 3, stroke = .5))
  )

ggplot2::ggsave(
  filename = file.path(data_dir, "distance to nearest green space mag/UPRN_2_1_greenspace_distances_doorstop_greenspace.png"),
  width = 12,
  height = 11,
  dpi = 300
)

### distance_local_greenspace ----
greenspace_distances_v3_sf |>
  # dplyr::filter(abs(distance_local_greenspace) <= 300) |>
  dplyr::arrange(distance_local_greenspace) |>
  ggplot2::ggplot() +
  ggplot2::geom_sf(ggplot2::aes(fill = distance_local_greenspace),
                   stroke = 0.01,
                   size = 0.75,
                   shape = 21) +
  ggplot2::geom_sf(data = uk_counties, fill = NA) +
  ggplot2::scale_fill_distiller(
    palette = "Spectral",
    breaks = scales::breaks_pretty(9)
  ) +
  ggplot2::labs(
    title = "UPRN level greenspace access indicator",
    subtitle = "Distance to local greenspace",
    fill = "Distance [m]",
    x = "Longitude",
    y = "Latitude"
  ) +
  ggplot2::theme_bw() +
  ggplot2::guides(
    fill = ggplot2::guide_legend(override.aes = list(size = 3, stroke = .5))
  )

ggplot2::ggsave(
  filename = file.path(data_dir, "distance to nearest green space mag/UPRN_2_1_greenspace_distances_local_greenspace.png"),
  width = 12,
  height = 11,
  dpi = 300
)

### distance_neighbourhood_greenspace ----
greenspace_distances_v3_sf |>
  dplyr::arrange(distance_neighbourhood_greenspace) |>
  ggplot2::ggplot() +
  ggplot2::geom_sf(ggplot2::aes(fill = distance_neighbourhood_greenspace),
                   stroke = 0.01,
                   size = 0.75,
                   shape = 21) +
  ggplot2::geom_sf(data = uk_counties, fill = NA) +
  ggplot2::scale_fill_distiller(
    palette = "Spectral",
    breaks = scales::breaks_pretty(9)
  ) +
  ggplot2::labs(
    title = "UPRN level greenspace access indicator",
    subtitle = "Distance to neighbourhood greenspace",
    fill = "Distance [m]",
    x = "Longitude",
    y = "Latitude"
  ) +
  ggplot2::theme_bw() +
  ggplot2::guides(
    fill = ggplot2::guide_legend(override.aes = list(size = 3, stroke = .5))
  )

ggplot2::ggsave(
  filename = file.path(data_dir, "distance to nearest green space mag/UPRN_2_1_greenspace_distances_neighbourhood_greenspace.png"),
  width = 12,
  height = 11,
  dpi = 300
)

### distance_wider_greenspace ----
greenspace_distances_v3_sf |>
  dplyr::arrange(distance_wider_greenspace) |>
  ggplot2::ggplot() +
  ggplot2::geom_sf(ggplot2::aes(fill = distance_wider_greenspace),
                   stroke = 0.01,
                   size = 0.75,
                   shape = 21) +
  ggplot2::geom_sf(data = uk_counties, fill = NA) +
  ggplot2::scale_fill_distiller(
    palette = "Spectral",
    breaks = scales::breaks_pretty(9)
  ) +
  ggplot2::labs(
    title = "UPRN level greenspace access indicator",
    subtitle = "Distance to wider greenspace",
    fill = "Distance [m]",
    x = "Longitude",
    y = "Latitude"
  ) +
  ggplot2::theme_bw() +
  ggplot2::guides(
    fill = ggplot2::guide_legend(override.aes = list(size = 3, stroke = .5))
  )

ggplot2::ggsave(
  filename = file.path(data_dir, "distance to nearest green space mag/UPRN_2_1_greenspace_distances_wider_greenspace.png"),
  width = 12,
  height = 11,
  dpi = 300
)

### distance_district_greenspace ----
greenspace_distances_v3_sf |>
  dplyr::arrange(distance_district_greenspace) |>
  ggplot2::ggplot() +
  ggplot2::geom_sf(ggplot2::aes(fill = distance_district_greenspace),
                   stroke = 0.01,
                   size = 0.75,
                   shape = 21) +
  ggplot2::geom_sf(data = uk_counties, fill = NA) +
  ggplot2::scale_fill_distiller(
    palette = "Spectral",
    breaks = scales::breaks_pretty(9)
  ) +
  ggplot2::labs(
    title = "UPRN level greenspace access indicator",
    subtitle = "Distance to district greenspace",
    fill = "Distance [m]",
    x = "Longitude",
    y = "Latitude"
  ) +
  ggplot2::theme_bw() +
  ggplot2::guides(
    fill = ggplot2::guide_legend(override.aes = list(size = 3, stroke = .5))
  )

ggplot2::ggsave(
  filename = file.path(data_dir, "distance to nearest green space mag/UPRN_2_1_greenspace_distances_district_greenspace.png"),
  width = 12,
  height = 11,
  dpi = 300
)

### distance_subregional_greenspace ----
greenspace_distances_v3_sf |>
  dplyr::arrange(distance_subregional_greenspace) |>
  ggplot2::ggplot() +
  ggplot2::geom_sf(ggplot2::aes(fill = distance_subregional_greenspace),
                   stroke = 0.01,
                   size = 0.75,
                   shape = 21) +
  ggplot2::geom_sf(data = uk_counties, fill = NA) +
  ggplot2::scale_fill_distiller(
    palette = "Spectral",
    breaks = scales::breaks_pretty(9)
  ) +
  ggplot2::labs(
    title = "UPRN level greenspace access indicator",
    subtitle = "Distance to subregional greenspace",
    fill = "Distance [m]",
    x = "Longitude",
    y = "Latitude"
  ) +
  ggplot2::theme_bw() +
  ggplot2::guides(
    fill = ggplot2::guide_legend(override.aes = list(size = 3, stroke = .5))
  )

ggplot2::ggsave(
  filename = file.path(data_dir, "distance to nearest green space mag/UPRN_2_1_greenspace_distances_subregional_greenspace.png"),
  width = 12,
  height = 11,
  dpi = 300
)

## 3.2. bluespace distances ----
# re-load indicator (in case only the visualisations are executed)
bluespace_distances_v3 <- file.path(data_dir, "Blue space indicators/UPRN_4_1_bluespace_distances_with_coords.csv") |>
  readr::read_csv()

# create spatial object for the metric
bluespace_distances_v3_sf <- bluespace_distances_v3 |>
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

### distance_any_bluespace ----
bluespace_distances_v3_sf |>
  dplyr::arrange(distance_any_bluespace) |>
  ggplot2::ggplot() +
  ggplot2::geom_sf(ggplot2::aes(fill = distance_any_bluespace),
                   stroke = 0.01,
                   size = 0.75,
                   shape = 21) +
  ggplot2::geom_sf(data = uk_counties, fill = NA) +
  ggplot2::scale_fill_distiller(
    palette = "Spectral",
    breaks = scales::breaks_pretty(9)
  ) +
  ggplot2::labs(
    title = "UPRN level bluespace access indicator",
    subtitle = "Distance to any bluespace",
    fill = "Distance [m]",
    x = "Longitude",
    y = "Latitude"
  ) +
  ggplot2::theme_bw() +
  ggplot2::guides(
    fill = ggplot2::guide_colourbar(
      position = "bottom",
      theme = ggplot2::theme(
        legend.key.width  = ggplot2::unit(30, "lines"),
        legend.key.height = ggplot2::unit(2, "lines")
      )
      # ggplot2::guide_legend(override.aes = list(size = 3, stroke = .5))
    )
  )

ggplot2::ggsave(
  filename = file.path(data_dir, "Blue space indicators/UPRN_4_1_bluespace_distances_any_bluespace.png"),
  width = 11,
  height = 12,
  dpi = 300
)
