##############################
### Processing input files ###
##############################

## Aim: To subset all UPRNs for Cheshire and Merseyside, aggregate them to TOIDs and save in the format required for the model.

# Libraries
library(data.table)
library(arrow)
library(sf)


### 1. Process the UPRNs for Cheshire and Merseyside ###

## If have a smaller dataset, then just use UPRNs and follow the code below ##

# # Load UPRNs
# uprn <- fread("C:/Users/mgreen/Google Drive/Colab/ukroutes/data/raw/onspd/osopenuprn_202405_csv/osopenuprn_202405.csv") # All UPRNs for GB and their points, then load the following April 2024 data via https://geoportal.statistics.gov.uk/datasets/acd0dbf73c2849f2a45e15c4aa248805/about - gives UPRN IDs and their locational information (exact point)
# uprn_lkup <- fread("C:/Users/mgreen/Google Drive/Colab/ukroutes/data/raw/onspd/NSUL_APR_2024/Data/NSUL_APR_2024_NW.csv") # This is a lookup file linking the UPRNs to spatial identifiers for the North West UPRNs for April 2024 https://geoportal.statistics.gov.uk/datasets/02d709e510804d67b16068b037cd72e6/about 
# uprn_lkup <- merge(uprn_lkup, uprn, by = "UPRN", all.x = TRUE) # Join on exact locations to NW dataset
# rm(uprn)
# 
# # Subset only Cheshire and Merseyside
# uprn_cm <- uprn_lkup[uprn_lkup$lad23cd == "E06000049" | uprn_lkup$lad23cd == "E06000050" | uprn_lkup$lad23cd == "E06000006" | uprn_lkup$lad23cd == "E08000011" | uprn_lkup$lad23cd == "E08000012" | uprn_lkup$lad23cd == "E08000014" | uprn_lkup$lad23cd == "E08000013" | uprn_lkup$lad23cd == "E06000007" | uprn_lkup$lad23cd == "E08000015",] # Local Authority Codes in order are: Cheshire East, Cheshire West and Chester, Halton, Knowsley, Liverpool, Sefton, St Helens, Warrington, Wirral
# rm(uprn_lkup)
# 
# # Process into required format
# names(uprn_cm)[names(uprn_cm) == "UPRN"] <- "PCD" # Rename variables to match format required in Python code
# names(uprn_cm)[names(uprn_cm) == "X_COORDINATE"] <- "OSEAST1M"
# names(uprn_cm)[names(uprn_cm) == "Y_COORDINATE"] <- "OSNRTH1M"
# uprn_cm <- uprn_cm[, c("PCD", "OSEAST1M", "OSNRTH1M")] # drop variables not required
# uprn_cm <- uprn_cm[!is.na(uprn_cm$OSEAST1M)] # Drop missing data (76 with missing locations)
# write.csv(uprn_cm, "C:/Users/mgreen/Google Drive/Colab/ukroutes/data/raw/onspd/ONSPD_FEB_2024.csv")
# write_parquet(uprn_cm, "C:/Users/mgreen/Google Drive/Colab/ukroutes/data/processed/postcodes.parquet") # Save
# rm(uprn_cm)
# gc()


### Faster approach when big datasets - use TOIDs for processing then link back to UPRNs later ###

# Note: Using TOIDs means 23% fewer points

# Load TOIDs
toid <- fread("../data/raw/os_uprns/osopentoid_202405_csv_sd/osopentoid_202405_sd.csv") # Download via https://www.ordnancesurvey.co.uk/products/os-open-toid (downloaded 2nd July 2024)
toid_sj <- fread("../data/raw/os_uprns/osopentoid_202405_csv_sj/osopentoid_202405_sj.csv") # Select all relevant regions
toid <- rbind(toid, toid_sj) # Join together into a single file
toid <- toid[, c("TOID", "EASTING", "NORTHING")] # Keep only variables required
rm(toid_sj) # Save space
gc()

# Get information to subset TOIDs for Cheshire and Merseyside
lkup <- fread("../data/raw/os_uprns/lids-2024-06_csv_BLPU-UPRN-TopographicArea-TOID-5/BLPU_UPRN_TopographicArea_TOID_5.csv") #  Load UPRN to TOID lookup (via https://www.ordnancesurvey.co.uk/products/os-open-linked-identifiers) - need the BLPU UPRN to Topographic TOID one (downloaded 2nd July 2024)
lkup <- lkup[, c("IDENTIFIER_1", "IDENTIFIER_2")] # Keep only variables required
names(lkup)[names(lkup) == "IDENTIFIER_1"] <- "UPRN" # Rename variables
names(lkup)[names(lkup) == "IDENTIFIER_2"] <- "TOID"
lkup2 <- fread("../data/raw/os_uprns/NSUL_APR_2024/Data/NSUL_APR_2024_NW.csv") # UPRN lookup table to spatial identifiers - April 2024 dataset downloaded 2nd July 2024 via https://geoportal.statistics.gov.uk/datasets/02d709e510804d67b16068b037cd72e6/about 
lkup2 <- lkup2[, c("UPRN", "lad23cd")] # Keep only variables required
lkup <- merge(lkup, lkup2, by = "UPRN", all.x = TRUE) # Join together
lkup <- lkup[!is.na(hold$lad23cd)] # Drop TOIDs not in the North West
# Subset only Cheshire and Merseyside
uprn_cm <- lkup[lkup$lad23cd == "E06000049" | lkup$lad23cd == "E06000050" | lkup$lad23cd == "E06000006" | lkup$lad23cd == "E08000011" | lkup$lad23cd == "E08000012" | lkup$lad23cd == "E08000014" | lkup$lad23cd == "E08000013" | lkup$lad23cd == "E06000007" | lkup$lad23cd == "E08000015",] # Local Authority Codes in order are: Cheshire East, Cheshire West and Chester, Halton, Knowsley, Liverpool, Sefton, St Helens, Warrington, Wirral
write_parquet(unique_data <- unique(data, by = "TOID"), "../data/processed/uprn_toid_cm_lkup.parquet") # Save lookup table
rm(lkup, lkup2) # Tidy
gc()

# Create a Cheshire and Merseyside TOID dataset
uprn_cm <- read_parquet("../data/processed/uprn_toid_cm_lkup.parquet") # Load UPRN to TOID lookup
toid_cm <- unique(uprn_cm, by = "TOID") # Aggregate to unique TOID values (as duplicate values for each UPRN)
toid_cm <- toid_cm[, 2:3] # Delete the UPRN column
toid_cm <- merge(toid_cm, toid, by = "TOID", all.x = TRUE) # Join on the spatial locations of TOIDs
toid_cm <- toid_cm[!is.na(toid_cm$EASTING)] # Drop if missing location (n=20)
write_parquet(toid_cm, "../data/processed/toids_cm_osgb.parquet") # Save
rm(toid, uprn_cm) # tidy
gc()

# Convert file into latitude and longitude (necessary for Google Earth Engine)
toid_sf <- st_as_sf(toid_cm, coords = c("EASTING", "NORTHING"), crs = 27700) # Convert to an sf object
toid_sf <- st_transform(toid_sf, crs = 4326) # Transform the coordinates to WGS84
toid_cm$latitude <- st_coordinates(toid_sf)[, 2] # Extract the latitude and longitude
toid_cm$longitude <- st_coordinates(toid_sf)[, 1]
write_parquet(toid_cm, "../data/processed/toids_cm.parquet") # Save
rm(toid_sf, toid_cm) # Tidy
gc()




### 2. Clean green space data into required indicators ###

# Load green space access points
osgsl <- read_sf("../data/raw/osgsl/opgrsp_essh_gb/OS Open Greenspace (ESRI Shape File) GB/data/GB_AccessPoint.shp") # All of Great Britain

# Subset C&M points
cm_lsoas <- read_sf("../../spatial_files/cm_lsoas.shp") # Load in C&M shapefile
# Dissolve all boundaries
dissolved_areas <- st_union(cm_lsoas) # Dissolve all boundaries so a single area extent
cm_buffer <- st_buffer(dissolved_areas, dist = 1000) # Add buffer around border - 1km
osgsl_cm <- st_intersection(osgsl, cm_buffer) # Subset only points within the spatial extent of above buffer

# Process to required format
coordinates <- st_coordinates(osgsl_cm) # Get easting and northing
coordinates_df <- as.data.frame(coordinates) # Convert the coordinates to a data frame 
colnames(coordinates_df) <- c("easting", "northing") # Rename columns

# Append the coordinates to the original object
osgsl_cm$easting <- coordinates_df$easting
osgsl_cm$northing <- coordinates_df$northing

# Process into format for saving
osgsl_cm <- data.frame(osgsl_cm) # Convert format
osgsl_new <- osgsl_cm[, c("id", "easting", "northing")] # Subset vars needed
write_parquet(osgsl_new, "../data/raw/osgsl/osgsl.parquet") # Save

