#' Download latest OS Open TOIDs
#'
#' @param area String with OS British National Grid ID (100km resolution).
#'     Available map tile references are: HP, HT, HU, HW, HX, HY, HZ, NA, NB,
#'     NC, ND, NF, NG, NH, NJ, NK, NL, NM, NN, NO, NR, NS, NT, NU, NW, NX, NY,
#'     NZ, SD, SE, TA, SH, SJ, SK, TF, TG, SM, SN, SO, SP, TL, TM, SR, SS, ST,
#'     SU, TQ, TR, SV, SW, SX, SY, SZ, TV
#' @param timeout Integer with maximum timeout to download data.
#'
#' @return Data frame with latest OS Open TOIDs for `area`.
#' @export
#'
#' @source https://osdatahub.os.uk/downloads/open/OpenTOID
#'
#' @examples
#' get_os_open_toids("NL")
get_os_open_toids <- function(area, timeout = 500) {
  # create temporary file
  tmp_file <- tempfile(fileext = ".zip")
  # base URL to OS API
  base_url <- "https://api.os.uk/downloads/v1/products/OpenTOID/downloads"
  # change timeout (slow downloads)
  oopt <- options(timeout = timeout)
  # download latest OS Open TOID dataset for 'area'
  os_open_toid <- tryCatch({
    download.file(
      url = paste0(base_url, "?area=", area, "&format=CSV&redirect"),
      destfile = tmp_file
    )
    # extract data
    unzip(tmp_file, exdir = dirname(tmp_file))
    files <- list.files(
      path = dirname(tmp_file),
      pattern = "osopentoid*.*csv$",
      full.names = TRUE
    )

    # load the OS Open TOID dataset
    aux <- files[1] |> # read the latest version
      readr::read_csv()

    # remove temporary files
    unlink(tmp_file, recursive = TRUE, force = TRUE)
    unlink(dirname(tmp_file), recursive = TRUE, force = TRUE)

    return(aux)
  }, error = function(e) {
    return(NULL)
  })
  # reverse change in timeout
  options(oopt)
  return(os_open_toid)
}

#' Download latest OS Open Linked Identifiers
#'
#' @param ref String with the name of identifier mapping. Valid entries are
#'     "BLPU-UPRN-RoadLink", "BLPU-UPRN-Street-USRN",
#'     "BLPU-UPRN-TopographicArea", "ORRoadLink-GUID-RoadLink-TOID",
#'     "ORRoadNode-GUID-RoadLink-TOID", "Road-TOID-Street-USRN",
#'     "Road-TOID-TopographicArea-TOID", "RoadLink-TOID-Road-TOID",
#'     "RoadLink-TOID-Street-USRN", "RoadLink-TOID-TopographicArea-TOID",
#'     "Street-USRN-TopographicArea-TOID"
#' @param timeout Integer with maximum timeout to download data.
#' @param filter_1 Vector with IDs to filter the raw data. Use the
#'     `IDENTIFIER_1` column (e.g., UPRNs).
#' @param filter_2 Vector with IDs to filter the raw data. Use the
#'     `IDENTIFIER_2` column (e.g., TOIDs).
#'
#' @return Data frame with latest OS Open Linked Identifiers for `ref`.
#' @export
#'
#' @source https://osdatahub.os.uk/downloads/open/LIDS
#'
#' @examples
#' get_os_open_identifiers("BLPU-UPRN-TopographicArea")
get_os_open_identifiers <- function(ref, timeout = 500, filter_1 = NULL, filter_2 = NULL) {
  url <- "https://api.os.uk/downloads/v1/products/LIDS/downloads?area=GB&format=CSV&fileName="
  if (ref == "BLPU-UPRN-RoadLink") {
    url <- paste0(url, "lids-2024-09_csv_BLPU-UPRN-RoadLink-TOID-9.zip&redirect")
  } else if (ref == "BLPU-UPRN-Street-USRN") {
    url <- paste0(url, "lids-2024-09_csv_BLPU-UPRN-Street-USRN-11.zip&redirect")
  } else if (ref == "BLPU-UPRN-TopographicArea") {
    url <- paste0(url, "lids-2024-09_csv_BLPU-UPRN-TopographicArea-TOID-5.zip&redirect")
  } else if (ref == "ORRoadLink-GUID-RoadLink-TOID") {
    url <- paste0(url, "lids-2024-09_csv_ORRoadLink-GUID-RoadLink-TOID-12.zip&redirect")
  } else if (ref == "ORRoadNode-GUID-RoadLink-TOID") {
    url <- paste0(url, "lids-2024-09_csv_ORRoadNode-GUID-RoadLink-TOID-13.zip&redirect")
  } else if (ref == "Road-TOID-Street-USRN") {
    url <- paste0(url, "lids-2024-09_csv_Road-TOID-Street-USRN-10.zip&redirect")
  } else if (ref == "Road-TOID-TopographicArea-TOID") {
    url <- paste0(url, "lids-2024-09_csv_Road-TOID-TopographicArea-TOID-3.zip&redirect")
  } else if (ref == "RoadLink-TOID-Road-TOID") {
    url <- paste0(url, "lids-2024-09_csv_RoadLink-TOID-Road-TOID-7.zip&redirect")
  } else if (ref == "RoadLink-TOID-Street-USRN") {
    url <- paste0(url, "lids-2024-09_csv_RoadLink-TOID-Street-USRN-8.zip&redirect")
  } else if (ref == "RoadLink-TOID-TopographicArea-TOID") {
    url <- paste0(url, "lids-2024-09_csv_RoadLink-TOID-TopographicArea-TOID-2.zip&redirect")
  } else if (ref == "Street-USRN-TopographicArea-TOID") {
    url <- paste0(url, "lids-2024-09_csv_Street-USRN-TopographicArea-TOID-4.zip&redirect")
  }

  # create temporary file
  tmp_file <- tempfile(fileext = ".zip")
  # change timeout (slow downloads)
  oopt <- options(timeout = timeout)
  # download latest OS Open Linked Identifiers dataset
  os_open_ids <- tryCatch({
    download.file(
      url = url,
      destfile = tmp_file
    )

    # extract data
    unzip(tmp_file, exdir = dirname(tmp_file))
    files <- list.files(
      path = dirname(tmp_file),
      pattern = ref |>
        stringr::str_replace_all(pattern = "-", replacement = "_") |>
        stringr::str_c("*.*csv$"),
      full.names = TRUE
    )

    # load the OS Open TOID dataset
    if (!is.null(filter_1)) {
      aux <- data.table::fread(files[1])[IDENTIFIER_1 %in% filter_1]
    } else if(!is.null(filter_2)) {
      aux <- data.table::fread(files[1])[IDENTIFIER_2 %in% filter_2]
    } else {
      aux <- data.table::fread(files[1])
    }

    # remove temporary files
    unlink(tmp_file, recursive = TRUE, force = TRUE)
    unlink(dirname(tmp_file), recursive = TRUE, force = TRUE)

    return(aux)
  }, error = function(e) {
    print(e)
    return(NULL)
  })
  # reverse change in timeout
  options(oopt)
  return(os_open_ids)
}
