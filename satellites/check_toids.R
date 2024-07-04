#################################################
### Check the quality of satellite indicators ###
#################################################

## Aims: (i) To load in the processed TOIDs, combine the files together, link to UPRNs, and save this int the required format. (ii) To assess if there are any issues with the quality of estimates.

# Libraries
library(data.table)
library(arrow)


## Part 1: Combine into a single file ##

# Load in each Local Authority file
che <- fread("./processed/Cheshire_East_Vegetation_Water_Indices_Medians.csv")
chw <- fread("./processed/Chester_and_Cheshire_West_Vegetation_Water_Indices_Medians.csv")
hal <- fread("./processed/Halton_Vegetation_Water_Indices_Medians.csv")
kno <- fread("./processed/Knowsley_Vegetation_Water_Indices_Medians.csv")
liv <- fread("./processed/Liverpool_Vegetation_Water_Indices_Medians.csv")
sef <- fread("./processed/Sefton_Vegetation_Water_Indices_Medians.csv")
sth <- fread("./processed/St_Helens_Vegetation_Water_Indices_Medians.csv")
war <- fread("./processed/Warrington_Vegetation_Water_Indices_Medians.csv")
wir <- fread("./processed/Wirral_Vegetation_Water_Indices_Medians.csv")

# Combine to single file
toids_cm <- rbind(che, chw, hal, kno, liv, sef, sth, war, wir) # Merge files together
rm(che, chw, hal, kno, liv, sef, sth, war, wir) # Save space

# Link TOID values to UPRNs
lkup <- read_parquet("./uprn_toid_cm_lkup.parquet") # Load in UPRN to TOID lookup
uprn <- merge(lkup, toids_cm, by = c("TOID", "lad23cd"), all.x = TRUE) # Merge together

# Save
write_parquet(uprn, "./uprn_satellite_indicators.parquet") # Save
rm(uprn, lkup, toids_cm) # Tidy
gc()


## Part 2: Assess the quality of estimates ## 

# Load data
lkup <- read_parquet("./uprn_satellite_indicators.parquet") 

# Check if there are any missing values

# Map values to see if look ok / make sense


