########################################
### Convert indicators back to UPRNs ###
########################################

## Aim: Take all of the processed TOID distance to metrics and convert them into UPRN metrics for data linkage.

# Libraries
library(data.table)
library(arrow)


## Green space access indicators ##

# Load datasets
any <- fread("../data/out/distances_greenspace_any.csv") # Load file
district <- fread("../data/out/distances_greenspace_district.csv") # Repeat one-by-one
doorstop <- fread("../data/out/distances_greenspace_doorstop.csv")
local <- fread("../data/out/distances_greenspace_local.csv")
neighbourhood <- fread("../data/out/distances_greenspace_neighbourhood.csv")
subregional <- fread("../data/out/distances_greenspace_subregional.csv")
wider <- fread("../data/out/distances_greenspace_wider.csv")

# Rename variables
names(any)[names(any) == "distance"] <- "distance_any_greenspace"
names(district)[names(district) == "distance"] <- "distance_district_greenspace"
names(doorstop)[names(doorstop) == "distance"] <- "distance_doorstop_greenspace"
names(local)[names(local) == "distance"] <- "distance_local_greenspace"
names(neighbourhood)[names(neighbourhood) == "distance"] <- "distance_neighbourhood_greenspace"
names(subregional)[names(subregional) == "distance"] <- "distance_subregional_greenspace"
names(wider)[names(wider) == "distance"] <- "distance_wider_greenspace"

# Join together into single file
combined <- merge(any, doorstop, by = "TOID") # Do this one-by-one
combined <- merge(combined, local, by = "TOID")
combined <- merge(combined, neighbourhood, by = "TOID")
combined <- merge(combined, wider, by = "TOID")
combined <- merge(combined, district, by = "TOID")
combined <- merge(combined, subregional, by = "TOID")
rm(any, doorstop, local, neighbourhood, wider, district, subregional) # Save space
gc()

# Create UPRN table
lkup <- read_parquet("../data/raw/os_uprns/uprn_toid_cm_lkup.parquet") # Load lookup table for TOID to UPRN
lkup <- merge(lkup, combined, by = "TOID", all.x = TRUE) # Join on distances to UPRNs
write.csv(lkup, "../data/out/uprn_greenspace_distances.csv") # Save

# Get LSOA code for each UPRN
lkup2 <- fread("../data/raw/os_uprns/NSUL_JUL_2024/Data/NSUL_JUL_2024_NW.csv") # UPRN lookup table to statistical geographies is available via https://geoportal.statistics.gov.uk/datasets/5cc894923c89483a832576a066464ec1/about 
lkup2 <- lkup2[, c("UPRN", "lsoa21cd")] # Keep only variables required
lkup <- merge(lkup, lkup2, by = "UPRN", all.x = TRUE) # Join onto distances file
rm(lkup2) # Tidy

# Create LSOA median average value
lsoas <- lkup[, .(
  distance_any_greenspace = median(distance_any_greenspace, na.rm = TRUE),
  distance_doorstop_greenspace = median(distance_doorstop_greenspace, na.rm = TRUE),
  distance_local_greenspace = median(distance_local_greenspace, na.rm = TRUE),
  distance_neighbourhood_greenspace = median(distance_neighbourhood_greenspace, na.rm = TRUE),
  distance_wider_greenspace = median(distance_wider_greenspace, na.rm = TRUE),
  distance_district_greenspace = median(distance_district_greenspace, na.rm = TRUE),
  distance_subregional_greenspace = median(distance_subregional_greenspace, na.rm = TRUE)
), by = lsoa21cd]

# Add on LSOA 2011 to 2021 lookup
lsoalkup <- fread("../data/raw/os_uprns/LSOA_(2011)_to_LSOA_(2021)_to_Local_Authority_District_(2022)_Best_Fit_Lookup_for_EW_(V2).csv") # Lookup via https://geoportal.statistics.gov.uk/datasets/b14d449ba10a48508bd05cd4a9775e2b/explore
lsoalkup <- lsoalkup[, c("LSOA11CD", "LSOA21CD")] # Keep only variables required
names(lsoas)[names(lsoas) == "lsoa21cd"] <- "LSOA21CD" # Rename to match
lsoas <- merge(lsoas, lsoalkup, by = "LSOA21CD", all.x = TRUE) # Join together
write.csv(lsoas, "../data/out/lsoa_greenspace_distances.csv") # Save



