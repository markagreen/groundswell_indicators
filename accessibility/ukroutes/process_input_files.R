##############################
### Processing input files ###
##############################


## 1. Process the UPRNs for Cheshire and Merseyside

# Load UPRNs
library(data.table)
library(arrow)
uprn <- fread("C:/Users/mgreen/Google Drive/Colab/ukroutes/data/raw/onspd/osopenuprn_202405_csv/osopenuprn_202405.csv") # All UPRNs for GB and their points, then load the following April 2024 data via https://geoportal.statistics.gov.uk/datasets/acd0dbf73c2849f2a45e15c4aa248805/about - gives UPRN IDs and their locational information (exact point)
uprn_lkup <- fread("C:/Users/mgreen/Google Drive/Colab/ukroutes/data/raw/onspd/NSUL_APR_2024/Data/NSUL_APR_2024_NW.csv") # This is a lookup file linking the UPRNs to spatial identifiers for the North West UPRNs for April 2024 https://geoportal.statistics.gov.uk/datasets/02d709e510804d67b16068b037cd72e6/about 
uprn_lkup <- merge(uprn_lkup, uprn, by = "UPRN", all.x = TRUE) # Join on exact locations to NW dataset
rm(uprn)

# Subset only Cheshire and Merseyside
uprn_cm <- uprn_lkup[uprn_lkup$lad23cd == "E06000049" | uprn_lkup$lad23cd == "E06000050" | uprn_lkup$lad23cd == "E06000006" | uprn_lkup$lad23cd == "E08000011" | uprn_lkup$lad23cd == "E08000012" | uprn_lkup$lad23cd == "E08000014" | uprn_lkup$lad23cd == "E08000013" | uprn_lkup$lad23cd == "E06000007" | uprn_lkup$lad23cd == "E08000015",] # Local Authority Codes in order are: Cheshire East, Cheshire West and Chester, Halton, Knowsley, Liverpool, Sefton, St Helens, Warrington, Wirral
rm(uprn_lkup)

# v1 - need to edit the Python code to allow
# # Rename vars
# names(uprn)[names(uprn) == "UPRN"] <- "uprn"
# names(uprn)[names(uprn) == "X_COORDINATE"] <- "easting"
# names(uprn)[names(uprn) == "Y_COORDINATE"] <- "northing"
# 
# # Delete vars
# uprn$LATITUDE <- NULL
# uprn$LONGITUDE <- NULL
# 
# # Subset small
# uprn_small <- uprn[1:100,]
# 
# # Save
# write_parquet(uprn_small, "C:/Users/mgreen/Google Drive/Colab/ukroutes/data/raw/onspd/uprn.parquet")

# v2
names(uprn_cm)[names(uprn_cm) == "UPRN"] <- "PCD" # Rename variables to match format required in Python code
names(uprn_cm)[names(uprn_cm) == "X_COORDINATE"] <- "OSEAST1M"
names(uprn_cm)[names(uprn_cm) == "Y_COORDINATE"] <- "OSNRTH1M"
uprn_cm <- uprn_cm[, c("PCD", "OSEAST1M", "OSNRTH1M")] # drop variables not required
uprn_cm <- uprn_cm[!is.na(uprn_cm$OSEAST1M)] # Drop missing data (76 with missing locations)
write.csv(uprn_cm, "C:/Users/mgreen/Google Drive/Colab/ukroutes/data/raw/onspd/ONSPD_FEB_2024.csv")
write_parquet(uprn_cm, "C:/Users/mgreen/Google Drive/Colab/ukroutes/data/processed/postcodes.parquet") # Save
rm(uprn_cm)
gc()

## 2. Clean green space data into required indicators

# Load green space access points
library(sf)
osgsl <- read_sf("C:/Users/mgreen/Google Drive/Colab/ukroutes/data/raw/osgsl/opgrsp_essh_gb/OS Open Greenspace (ESRI Shape File) GB/data/GB_AccessPoint.shp") # All of Great Britain

# Subset C&M points
cm_lsoas <- read_sf("C:/Users/mgreen/Google Drive/Colab/ukroutes/spatial_files/cm_lsoas.shp") # Load in C&M shapefile
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
library(arrow)
write_parquet(osgsl_new, "C:/Users/mgreen/Google Drive/Colab/ukroutes/data/raw/osgsl/osgsl.parquet") # Save

