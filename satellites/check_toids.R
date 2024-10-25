#################################################
### Check the quality of satellite indicators ###
#################################################

## Aims: (i) To load in the processed TOIDs, combine the files together, link to UPRNs, and save this int the required format. (ii) To assess if there are any issues with the quality of estimates.

# Note: Rather than doing this in one big loop, I have split them out individually so that I can inspect each file at a time.

# Libraries
library(data.table)
library(ggplot2) 
library(arrow)
library(sf)


## Wirral ##

# Define where to load data from
files <- list.files("./processed/E08000015", pattern = "\\.csv$", full.names = TRUE) # Define where data stored
combined_data <- data.frame() # Initialize an empty data frame to store combined data

# Loop through each file within the folder to load them and combine into a single file
for (file in files) { # Loop through files one at a time
  data <- fread(file) # Load 
  combined_data <- rbind(combined_data, data)  # Combine data with existing
}
rm(data, file, files) # Tidy

# Drop unnecessary variable
combined_data <- combined_data[, 2:5]

# Join onto TOIDs dataset
toids_cm <- read_parquet("./toids_cm_osgb.parquet") # Load TOID spatial location data
wirral <- toids_cm[toids_cm$lad23cd == "E08000015"] # Subset Wirral TOIDs 
wirral <- merge(wirral, combined_data, by = "TOID", all.x = TRUE) # Join satellite estimates onto TOID location information

# Map values to see if look ok / make sense
wirral_sf <- st_as_sf(wirral, coords = c("EASTING", "NORTHING"), crs = 27700) # Convert to an sf object
ggplot() + # Plot NDVI
  geom_sf(data = wirral_sf, aes(color = NDVI), lwd = 0, size = 0.1)
ggplot() + # Plot EVI
  geom_sf(data = wirral_sf, aes(color = EVI), lwd = 0, size = 0.1)
ggplot() + # Plot NDWI
  geom_sf(data = wirral_sf, aes(color = NDWI), lwd = 0, size = 0.1)
rm(toids_cm, combined_data)

# Check if there are any missing values
summary(wirral_sf) # Check missingness 
test <- wirral_sf[is.na(wirral_sf$NDVI),] # Store missing values
test <- st_transform(test, crs = 4326) # Transform the coordinates to WGS84
test # Update images to incoporate extents of missing values and then re-process

# Create UPRN dataset
uprn_lkup <- read_parquet("./uprn_toid_cm_lkup.parquet") # Load in UPRN to TOID lookup table
uprn_lkup_wir <- uprn_lkup[uprn_lkup$lad23cd == "E08000015",] # Subset Wirral UPRNs
uprn_lkup_wir <- merge(uprn_lkup_wir, wirral, by = c("TOID", "lad23cd"), all.x = TRUE) # Join on satellite values
write_parquet(uprn_lkup_wir, "./uprn_wirral.parquet") # Save
rm(uprn_lkup,uprn_lkup_wir, wirral, wirral_sf, test) # Tidy


## Cheshire East ##

# Define where to load data from
files <- list.files("./processed/E06000049", pattern = "\\.csv$", full.names = TRUE) # Define where data stored
combined_data <- data.frame() # Initialize an empty data frame to store combined data

# Loop through each file within the folder to load them and combine into a single file
for (file in files) { # Loop through files one at a time
  data <- fread(file) # Load 
  combined_data <- rbind(combined_data, data)  # Combine data with existing
}
rm(data, file, files) # Tidy

# Drop unnecessary variable
combined_data <- combined_data[, 2:5]

# Join onto TOIDs dataset
toids_cm <- read_parquet("./toids_cm_osgb.parquet") # Load TOID spatial location data
ches_e <- toids_cm[toids_cm$lad23cd == "E06000049"] # Subset Wirral TOIDs 
ches_e <- merge(ches_e, combined_data, by = "TOID", all.x = TRUE) # Join satellite estimates onto TOID location information

# Map values to see if look ok / make sense
ches_e_sf <- st_as_sf(ches_e, coords = c("EASTING", "NORTHING"), crs = 27700) # Convert to an sf object
ggplot() + # Plot NDVI
  geom_sf(data = ches_e_sf, aes(color = NDVI), lwd = 0, size = 0.1)
ggplot() + # Plot EVI
  geom_sf(data = ches_e_sf, aes(color = EVI), lwd = 0, size = 0.1)
ggplot() + # Plot NDWI
  geom_sf(data = ches_e_sf, aes(color = NDWI), lwd = 0, size = 0.1)
ggplot() + # Plot missing data
  geom_sf(data = ches_e_sf[is.na(ches_e_sf$NDVI),], aes(color = NDWI), lwd = 0, size = 0.1)
rm(toids_cm, combined_data)

# Check if there are any missing values
summary(ches_e) # Check missingness
test <- ches_e_sf[is.na(ches_e_sf$NDVI),] # Store missing values
test <- st_transform(test, crs = 4326) # Transform the coordinates to WGS84
test # Update images to incoporate extents of missing values and then re-process

# Create UPRN dataset
uprn_lkup <- read_parquet("./uprn_toid_cm_lkup.parquet") # Load in UPRN to TOID lookup table
uprn_lkup_che <- uprn_lkup[uprn_lkup$lad23cd == "E06000049",] # Subset Wirral UPRNs
uprn_lkup_che <- merge(uprn_lkup_che, ches_e, by = c("TOID", "lad23cd"), all.x = TRUE) # Join on satellite values
write_parquet(uprn_lkup_che, "./uprn_cheast.parquet") # Save
rm(uprn_lkup, uprn_lkup_che, ches_e, ches_e_sf, test) # Tidy


## Sefton ##

# Define where to load data from
files <- list.files("./processed/E08000014", pattern = "\\.csv$", full.names = TRUE) # Define where data stored
combined_data <- data.frame() # Initialize an empty data frame to store combined data

# Loop through each file within the folder to load them and combine into a single file
for (file in files) { # Loop through files one at a time
  data <- fread(file) # Load 
  combined_data <- rbind(combined_data, data)  # Combine data with existing
}
rm(data, file, files) # Tidy

# Drop unnecessary variable
combined_data <- combined_data[, 2:5]

# Join onto TOIDs dataset
toids_cm <- read_parquet("./toids_cm_osgb.parquet") # Load TOID spatial location data
lad <- toids_cm[toids_cm$lad23cd == "E08000014"] # Subset TOIDs for Local Authority 
lad <- merge(lad, combined_data, by = "TOID", all.x = TRUE) # Join satellite estimates onto TOID location information

# Map values to see if look ok / make sense
lad_sf <- st_as_sf(lad, coords = c("EASTING", "NORTHING"), crs = 27700) # Convert to an sf object
ggplot() + # Plot NDVI
  geom_sf(data = lad_sf, aes(color = NDVI), lwd = 0, size = 0.1)
ggplot() + # Plot EVI
  geom_sf(data = lad_sf, aes(color = EVI), lwd = 0, size = 0.1)
ggplot() + # Plot NDWI
  geom_sf(data = lad_sf, aes(color = NDWI), lwd = 0, size = 0.1)
rm(toids_cm, combined_data)

# Check if there are any missing values
summary(lad_sf) # Check missingness
#test <- lad_sf[is.na(lad_sf$NDVI),] # Store missing values
#test <- st_transform(test, crs = 4326) # Transform the coordinates to WGS84
#test # Update images to incoporate extents of missing values and then re-process

# Create UPRN dataset
uprn_lkup <- read_parquet("./uprn_toid_cm_lkup.parquet") # Load in UPRN to TOID lookup table
uprn_lkup_lad <- uprn_lkup[uprn_lkup$lad23cd == "E08000014",] # Subset UPRNs for Local Authority
uprn_lkup_lad <- merge(uprn_lkup_lad, lad, by = c("TOID", "lad23cd"), all.x = TRUE) # Join on satellite values
write_parquet(uprn_lkup_lad, "./uprn_sefton.parquet") # Save
rm(uprn_lkup, uprn_lkup_lad, lad, lad_sf, test) # Tidy

## St. Helens ##

# Define where to load data from
files <- list.files("./processed/E08000013", pattern = "\\.csv$", full.names = TRUE) # Define where data stored
combined_data <- data.frame() # Initialize an empty data frame to store combined data

# Loop through each file within the folder to load them and combine into a single file
for (file in files) { # Loop through files one at a time
  data <- fread(file) # Load 
  combined_data <- rbind(combined_data, data)  # Combine data with existing
}
rm(data, file, files) # Tidy

# Drop unnecessary variable
combined_data <- combined_data[, 2:5]

# Join onto TOIDs dataset
toids_cm <- read_parquet("./toids_cm_osgb.parquet") # Load TOID spatial location data
lad <- toids_cm[toids_cm$lad23cd == "E08000013"] # Subset TOIDs for Local Authority 
lad <- merge(lad, combined_data, by = "TOID", all.x = TRUE) # Join satellite estimates onto TOID location information

# Map values to see if look ok / make sense
lad_sf <- st_as_sf(lad, coords = c("EASTING", "NORTHING"), crs = 27700) # Convert to an sf object
ggplot() + # Plot NDVI
  geom_sf(data = lad_sf, aes(color = NDVI), lwd = 0, size = 0.1)
ggplot() + # Plot EVI
  geom_sf(data = lad_sf, aes(color = EVI), lwd = 0, size = 0.1)
ggplot() + # Plot NDWI
  geom_sf(data = lad_sf, aes(color = NDWI), lwd = 0, size = 0.1)
rm(toids_cm, combined_data)

# Check if there are any missing values
summary(lad_sf) # Check missingness
#test <- lad_sf[is.na(lad_sf$NDVI),] # Store missing values
#test <- st_transform(test, crs = 4326) # Transform the coordinates to WGS84
#test # Update images to incoporate extents of missing values and then re-process

# Create UPRN dataset
uprn_lkup <- read_parquet("./uprn_toid_cm_lkup.parquet") # Load in UPRN to TOID lookup table
uprn_lkup_lad <- uprn_lkup[uprn_lkup$lad23cd == "E08000013",] # Subset UPRNs for Local Authority
uprn_lkup_lad <- merge(uprn_lkup_lad, lad, by = c("TOID", "lad23cd"), all.x = TRUE) # Join on satellite values
write_parquet(uprn_lkup_lad, "./uprn_st_helens.parquet") # Save
rm(uprn_lkup, uprn_lkup_lad, lad, lad_sf, test) # Tidy

## Liverpool ##

# Define where to load data from
files <- list.files("./processed/E08000012", pattern = "\\.csv$", full.names = TRUE) # Define where data stored
combined_data <- data.frame() # Initialize an empty data frame to store combined data

# Loop through each file within the folder to load them and combine into a single file
for (file in files) { # Loop through files one at a time
  data <- fread(file) # Load 
  combined_data <- rbind(combined_data, data)  # Combine data with existing
}
rm(data, file, files) # Tidy

# Drop unnecessary variable
combined_data <- combined_data[, 2:5]

# Join onto TOIDs dataset
toids_cm <- read_parquet("./toids_cm_osgb.parquet") # Load TOID spatial location data
lad <- toids_cm[toids_cm$lad23cd == "E08000012"] # Subset TOIDs for Local Authority 
lad <- merge(lad, combined_data, by = "TOID", all.x = TRUE) # Join satellite estimates onto TOID location information

# Map values to see if look ok / make sense
lad_sf <- st_as_sf(lad, coords = c("EASTING", "NORTHING"), crs = 27700) # Convert to an sf object
ggplot() + # Plot NDVI
  geom_sf(data = lad_sf, aes(color = NDVI), lwd = 0, size = 0.1)
ggplot() + # Plot EVI
  geom_sf(data = lad_sf, aes(color = EVI), lwd = 0, size = 0.1)
ggplot() + # Plot NDWI
  geom_sf(data = lad_sf, aes(color = NDWI), lwd = 0, size = 0.1)
rm(toids_cm, combined_data)

# Check if there are any missing values
summary(lad_sf) # Check missingness
test <- lad_sf[is.na(lad_sf$NDVI),] # Store missing values
test <- st_transform(test, crs = 4326) # Transform the coordinates to WGS84
test # Update images to incoporate extents of missing values and then re-process

# Create UPRN dataset
uprn_lkup <- read_parquet("./uprn_toid_cm_lkup.parquet") # Load in UPRN to TOID lookup table
uprn_lkup_lad <- uprn_lkup[uprn_lkup$lad23cd == "E08000012",] # Subset UPRNs for Local Authority
uprn_lkup_lad <- merge(uprn_lkup_lad, lad, by = c("TOID", "lad23cd"), all.x = TRUE) # Join on satellite values
write_parquet(uprn_lkup_lad, "./uprn_liverpool.parquet") # Save
rm(uprn_lkup, uprn_lkup_lad, lad, lad_sf, test) # Tidy

## Knowsley ##

# Define where to load data from
files <- list.files("./processed/E08000011", pattern = "\\.csv$", full.names = TRUE) # Define where data stored
combined_data <- data.frame() # Initialize an empty data frame to store combined data

# Loop through each file within the folder to load them and combine into a single file
for (file in files) { # Loop through files one at a time
  data <- fread(file) # Load 
  combined_data <- rbind(combined_data, data)  # Combine data with existing
}
rm(data, file, files) # Tidy

# Drop unnecessary variable
combined_data <- combined_data[, 2:5]

# Join onto TOIDs dataset
toids_cm <- read_parquet("./toids_cm_osgb.parquet") # Load TOID spatial location data
lad <- toids_cm[toids_cm$lad23cd == "E08000011"] # Subset TOIDs for Local Authority 
lad <- merge(lad, combined_data, by = "TOID", all.x = TRUE) # Join satellite estimates onto TOID location information

# Map values to see if look ok / make sense
lad_sf <- st_as_sf(lad, coords = c("EASTING", "NORTHING"), crs = 27700) # Convert to an sf object
ggplot() + # Plot NDVI
  geom_sf(data = lad_sf, aes(color = NDVI), lwd = 0, size = 0.1)
ggplot() + # Plot EVI
  geom_sf(data = lad_sf, aes(color = EVI), lwd = 0, size = 0.1)
ggplot() + # Plot NDWI
  geom_sf(data = lad_sf, aes(color = NDWI), lwd = 0, size = 0.1)
rm(toids_cm, combined_data)

# Check if there are any missing values
summary(lad_sf) # Check missingness
#test <- lad_sf[is.na(lad_sf$NDVI),] # Store missing values
#test <- st_transform(test, crs = 4326) # Transform the coordinates to WGS84
#test # Update images to incoporate extents of missing values and then re-process

# Create UPRN dataset
uprn_lkup <- read_parquet("./uprn_toid_cm_lkup.parquet") # Load in UPRN to TOID lookup table
uprn_lkup_lad <- uprn_lkup[uprn_lkup$lad23cd == "E08000011",] # Subset UPRNs for Local Authority
uprn_lkup_lad <- merge(uprn_lkup_lad, lad, by = c("TOID", "lad23cd"), all.x = TRUE) # Join on satellite values
write_parquet(uprn_lkup_lad, "./uprn_knowsley.parquet") # Save
rm(uprn_lkup, uprn_lkup_lad, lad, lad_sf, test) # Tidy

## Chester and Cheshire West ##

# Define where to load data from
files <- list.files("./processed/E06000050", pattern = "\\.csv$", full.names = TRUE) # Define where data stored
combined_data <- data.frame() # Initialize an empty data frame to store combined data

# Loop through each file within the folder to load them and combine into a single file
for (file in files) { # Loop through files one at a time
  data <- fread(file) # Load 
  combined_data <- rbind(combined_data, data)  # Combine data with existing
}
rm(data, file, files) # Tidy

# Drop unnecessary variable
combined_data <- combined_data[, 2:5]

# Join onto TOIDs dataset
toids_cm <- read_parquet("./toids_cm_osgb.parquet") # Load TOID spatial location data
lad <- toids_cm[toids_cm$lad23cd == "E06000050"] # Subset TOIDs for Local Authority 
lad <- merge(lad, combined_data, by = "TOID", all.x = TRUE) # Join satellite estimates onto TOID location information

# Map values to see if look ok / make sense
lad_sf <- st_as_sf(lad, coords = c("EASTING", "NORTHING"), crs = 27700) # Convert to an sf object
ggplot() + # Plot NDVI
  geom_sf(data = lad_sf, aes(color = NDVI), lwd = 0, size = 0.1)
ggplot() + # Plot EVI
  geom_sf(data = lad_sf, aes(color = EVI), lwd = 0, size = 0.1)
ggplot() + # Plot NDWI
  geom_sf(data = lad_sf, aes(color = NDWI), lwd = 0, size = 0.1)
rm(toids_cm, combined_data)

# Check if there are any missing values
summary(lad_sf) # Check missingness
test <- lad_sf[is.na(lad_sf$NDVI),] # Store missing values
test <- st_transform(test, crs = 4326) # Transform the coordinates to WGS84
test # Update images to incoporate extents of missing values and then re-process

# Create UPRN dataset
uprn_lkup <- read_parquet("./uprn_toid_cm_lkup.parquet") # Load in UPRN to TOID lookup table
uprn_lkup_lad <- uprn_lkup[uprn_lkup$lad23cd == "E06000050",] # Subset UPRNs for Local Authority
uprn_lkup_lad <- merge(uprn_lkup_lad, lad, by = c("TOID", "lad23cd"), all.x = TRUE) # Join on satellite values
write_parquet(uprn_lkup_lad, "./uprn_chchw.parquet") # Save
rm(uprn_lkup, uprn_lkup_lad, lad, lad_sf, test) # Tidy

## Halton ##

# Define where to load data from
files <- list.files("./processed/E06000006", pattern = "\\.csv$", full.names = TRUE) # Define where data stored
combined_data <- data.frame() # Initialize an empty data frame to store combined data

# Loop through each file within the folder to load them and combine into a single file
for (file in files) { # Loop through files one at a time
  data <- fread(file) # Load 
  combined_data <- rbind(combined_data, data)  # Combine data with existing
}
rm(data, file, files) # Tidy

# Drop unnecessary variable
combined_data <- combined_data[, 2:5]

# Join onto TOIDs dataset
toids_cm <- read_parquet("./toids_cm_osgb.parquet") # Load TOID spatial location data
lad <- toids_cm[toids_cm$lad23cd == "E06000006"] # Subset TOIDs for Local Authority 
lad <- merge(lad, combined_data, by = "TOID", all.x = TRUE) # Join satellite estimates onto TOID location information

# Map values to see if look ok / make sense
lad_sf <- st_as_sf(lad, coords = c("EASTING", "NORTHING"), crs = 27700) # Convert to an sf object
ggplot() + # Plot NDVI
  geom_sf(data = lad_sf, aes(color = NDVI), lwd = 0, size = 0.1)
ggplot() + # Plot EVI
  geom_sf(data = lad_sf, aes(color = EVI), lwd = 0, size = 0.1)
ggplot() + # Plot NDWI
  geom_sf(data = lad_sf, aes(color = NDWI), lwd = 0, size = 0.1)
rm(toids_cm, combined_data)

# Check if there are any missing values
summary(lad_sf) # Check missingness
test <- lad_sf[is.na(lad_sf$NDVI),] # Store missing values
test <- st_transform(test, crs = 4326) # Transform the coordinates to WGS84
test # Update images to incoporate extents of missing values and then re-process

# Create UPRN dataset
uprn_lkup <- read_parquet("./uprn_toid_cm_lkup.parquet") # Load in UPRN to TOID lookup table
uprn_lkup_lad <- uprn_lkup[uprn_lkup$lad23cd == "E06000006",] # Subset UPRNs for Local Authority
uprn_lkup_lad <- merge(uprn_lkup_lad, lad, by = c("TOID", "lad23cd"), all.x = TRUE) # Join on satellite values
write_parquet(uprn_lkup_lad, "./uprn_halton.parquet") # Save
rm(uprn_lkup, uprn_lkup_lad, lad, lad_sf, test) # Tidy


## Warrington ##

# Define where to load data from
files <- list.files("./processed/E06000007", pattern = "\\.csv$", full.names = TRUE) # Define where data stored
combined_data <- data.frame() # Initialize an empty data frame to store combined data

# Loop through each file within the folder to load them and combine into a single file
for (file in files) { # Loop through files one at a time
  data <- fread(file) # Load 
  combined_data <- rbind(combined_data, data)  # Combine data with existing
}
rm(data, file, files) # Tidy

# Drop unnecessary variable
combined_data <- combined_data[, 2:5]

# Join onto TOIDs dataset
toids_cm <- read_parquet("./toids_cm_osgb.parquet") # Load TOID spatial location data
lad <- toids_cm[toids_cm$lad23cd == "E06000007"] # Subset TOIDs for Local Authority 
lad <- merge(lad, combined_data, by = "TOID", all.x = TRUE) # Join satellite estimates onto TOID location information

# Map values to see if look ok / make sense
lad_sf <- st_as_sf(lad, coords = c("EASTING", "NORTHING"), crs = 27700) # Convert to an sf object
ggplot() + # Plot NDVI
  geom_sf(data = lad_sf, aes(color = NDVI), lwd = 0, size = 0.1)
ggplot() + # Plot EVI
  geom_sf(data = lad_sf, aes(color = EVI), lwd = 0, size = 0.1)
ggplot() + # Plot NDWI
  geom_sf(data = lad_sf, aes(color = NDWI), lwd = 0, size = 0.1)
rm(toids_cm, combined_data)

# Check if there are any missing values
summary(lad_sf) # Check missingness
test <- lad_sf[is.na(lad_sf$NDVI),] # Store missing values
test <- st_transform(test, crs = 4326) # Transform the coordinates to WGS84
test # Update images to incoporate extents of missing values and then re-process

# Create UPRN dataset
uprn_lkup <- read_parquet("./uprn_toid_cm_lkup.parquet") # Load in UPRN to TOID lookup table
uprn_lkup_lad <- uprn_lkup[uprn_lkup$lad23cd == "E06000007",] # Subset UPRNs for Local Authority
uprn_lkup_lad <- merge(uprn_lkup_lad, lad, by = c("TOID", "lad23cd"), all.x = TRUE) # Join on satellite values
write_parquet(uprn_lkup_lad, "./uprn_warrington.parquet") # Save
rm(uprn_lkup, uprn_lkup_lad, lad, lad_sf, test) # Tidy
gc()


## Combine all files into a single dataset ##

# Load all files
cheast <- read_parquet("./uprn_cheast.parquet") # Cheshire East
chwch <- read_parquet("./uprn_chchw.parquet") # Cheshire West and Chester
halt <- read_parquet("./uprn_halton.parquet") # Halton
know <- read_parquet("./uprn_knowsley.parquet") # Knowlsey
liv <- read_parquet("./uprn_liverpool.parquet") # Liverpool
seft <- read_parquet("./uprn_sefton.parquet") # Sefton
sthel <- read_parquet("./uprn_st_helens.parquet") # St. Helens
warr <- read_parquet("./uprn_warrington.parquet") # Warrington
wirr <- read_parquet("./uprn_wirral.parquet") # wirral

# Combine into single dataset
combined <- rbind(cheast, chwch, halt, know, liv, seft, sthel, warr, wirr)  
rm(cheast, chwch, halt, know, liv, seft, sthel, warr, wirr)  

# Save
write.csv(combined, "./uprn_satellite_measures.csv")
rm(combined)
gc()
