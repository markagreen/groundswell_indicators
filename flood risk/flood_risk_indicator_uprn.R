########################################
### Create UPRN flood risk indicator ###
########################################

# Aim: To create a UPRN lookup table that links whether each UPRN is located in an area at risk of flooding. 

# Libraries
library(data.table)
library(geos)
library(sf)

## Get all UPRNs for Cheshire and Merseyside ##

# Load UPRNs
uprn <- fread("C:/Users/mgreen/Google Drive/Colab/ukroutes/data/raw/onspd/osopenuprn_202405_csv/osopenuprn_202405.csv") # All UPRNs for GB and their points, then load the following April 2024 data via https://geoportal.statistics.gov.uk/datasets/acd0dbf73c2849f2a45e15c4aa248805/about - gives UPRN IDs and their locational information (exact point)
uprn_lkup <- fread("C:/Users/mgreen/Google Drive/Colab/ukroutes/data/raw/onspd/NSUL_APR_2024/Data/NSUL_APR_2024_NW.csv") # This is a lookup file linking the UPRNs to spatial identifiers for the North West UPRNs for April 2024 https://geoportal.statistics.gov.uk/datasets/02d709e510804d67b16068b037cd72e6/about 
uprn_lkup <- merge(uprn_lkup, uprn, by = "UPRN", all.x = TRUE) # Join on exact locations to NW dataset
rm(uprn)

# Subset only Cheshire and Merseyside
uprn_cm <- uprn_lkup[uprn_lkup$lad23cd == "E06000049" | uprn_lkup$lad23cd == "E06000050" | uprn_lkup$lad23cd == "E06000006" | uprn_lkup$lad23cd == "E08000011" | uprn_lkup$lad23cd == "E08000012" | uprn_lkup$lad23cd == "E08000014" | uprn_lkup$lad23cd == "E08000013" | uprn_lkup$lad23cd == "E06000007" | uprn_lkup$lad23cd == "E08000015",] # Local Authority Codes in order are: Cheshire East, Cheshire West and Chester, Halton, Knowsley, Liverpool, Sefton, St Helens, Warrington, Wirral
rm(uprn_lkup)

# Create spatial data frame version of UPRNs
uprn_cm_sp <- st_as_sf(uprn_cm, coords = c("GRIDGB1E", "GRIDGB1N"), crs = 27700)
rm(uprn_cm)

## Get DEFRA England flood risk maps ##

# Load datasets

# Surface water flood risk
surface <- read_sf("./IndicativeFloodRiskAreas-SHP/data/Blue_Square_Grid.shp") # Indicative flood risk areas via https://www.data.gov.uk/dataset/7792054a-068d-471b-8969-f53a22b0c9b2/indicative-flood-risk-areas-shapefiles
lsoas_cm <- read_sf("C:/Users/mgreen/Google Drive/Colab/ukroutes/spatial_files/cm_lsoas.shp") # Load Cheshire and Merseyside extent
dissolved_areas <- st_union(lsoas_cm) # Dissolve all boundaries so a single area extent
cm_buffer <- st_buffer(dissolved_areas, dist = 1000) # Add buffer around border - 1km
surface_cm <- st_intersection(surface, cm_buffer) # Subset only points within the spatial extent of above buffer
rm(lsoas_cm, dissolved_areas, cm_buffer, surface)

# Environment Agency's Risk of Flooding from Rivers and Sea dataset
# Download via https://environment.data.gov.uk/dataset/8d57464f-d465-11e4-8790-f0def148f590
# I had to use the manual download tool and download bounding boxes to cover the region - these need combining together

# Load each region 
rfrs_liv <- read_sf("./flooding_risk_rivers_seas/liverpool.json") # Liverpool
rfrs_sef <- read_sf("./flooding_risk_rivers_seas/sefton.json") # Sefton
rfrs_wir <- read_sf("./flooding_risk_rivers_seas/wirral.json") # Wirral
rfrs_khw <- read_sf("./flooding_risk_rivers_seas/knowsley_halton_warr.json") # Knowsley, Halton, Warrington
rfrs_che <- read_sf("./flooding_risk_rivers_seas/cheshire_east.json") # Cheshire East
rfrs_chw <- read_sf("./flooding_risk_rivers_seas/cheshire_west.json") # Cheshire West

# Combine
rfrs <- rbind(rfrs_liv, rfrs_sef, rfrs_wir, rfrs_khw, rfrs_che, rfrs_chw) # Join files together
rfrs <- st_transform(rfrs, crs = 27700) # Reproject to OSGB
# plot(rfrs[1]) # Check that worked
rm(rfrs_liv, rfrs_sef, rfrs_wir, rfrs_khw, rfrs_che, rfrs_chw) # Drop as no longer needed


## Create lookup of UPRN to surface flood risk area

# Store all values for Local Authority to help loop
segments <- unique(uprn_cm_sp$lad23cd)

# Create a spatial index (STRtree) for the flood risk data
flood <- geos_strtree(surface_cm)

# Identify if UPRN is located within a flood risk area
for (segment_id in segments) { #  Code loops over local authority as faster to run this way (~1min)
  # Print the current Local Authority (i.e., segment) to check progress
  cat("Processing segment:", segment_id, "\n")
  
  # Subset the UPRNs for the current segment
  current_segment <- uprn_cm_sp[uprn_cm_sp$lad23cd == segment_id, ]
  
  # Convert UPRNs to GEOS geometries for the current segment
  uprns_geos <- as_geos_geometry(current_segment)
  
  # Find the indices of UPRNs that are contained within flood risk zones
  keys <- geos_intersects_matrix(uprns_geos, flood)
  
  # Count the number of flood areas within each buffered UPRN
  count_per_uprn <- lengths(keys)
  
  # Create a data.table which stores final result
  count_data <- data.table(id = current_segment$UPRN, surface_flood_risk = count_per_uprn)
  
  # Revise count per UPRN into a binary
  count_data$surface_flood_risk[count_data$surface_flood_risk > 1] <- 1
  
  # Save the count data to a file (append mode)
  # This helps avoid R storing all the data in memory which may lead it to crash
  fwrite(count_data, file = "output_file_surface_flood.csv", append = TRUE)
  
  # Tidy to save memory (this step might be unncessary tbh and could just be adding time to do)
  rm(keys, uprns_geos, count_per_uprn, count_data, current_segment)
  
}

# Load processed file to check
output <- fread("C:/Users/mgreen/Google Drive/Papers/GroundsWell/WP4/Flooding/output_file_surface_flood.csv")
table(output$surface_flood_risk) # Check if has given 1s and 0s
rm(output)
gc()



## Create lookup of UPRN to risk of flooding by rivers and seas - indicator by level of risk

# Measure time to run
start_time <- Sys.time()

# Store all values for flood risk types
# risk_types <- c("High", "Low", "Medium", "Very Low")
risk_types <- unique(rfrs$prob_4band)

# Store all values for Local Authority to help loop
segments <- unique(uprn_cm_sp$lad23cd)

# Identify if UPRN is located within a flood risk area
for (segment_id in segments) { # Loop over each Local Authority to help R with storing data in memory (plus faster to run; 1.5 hrs)
  
  # Print the current Local Authority (i.e., segment) to check progress
  cat("Processing segment:", segment_id, "\n")
  
  # Subset the UPRNs for the current segment
  current_segment <- uprn_cm_sp[uprn_cm_sp$lad23cd == segment_id, ]

  # Loop over each flood risk type
  for (risk_type in risk_types) {
    
    # Print the current risk type to check progress
    #cat("Processing risk type:", risk_type, "\n")
    
    # Subset the indices for the current risk type
    current_risk_indices <- which(rfrs$prob_4band == risk_type)
    
    # Get the geometries for the current risk type
    current_risk_geos <- as_geos_geometry(rfrs[current_risk_indices, ])
    
    # Identify UPRNs located within the current flood risk type
    uprns_in_risk <- geos_intersects_matrix(as_geos_geometry(current_segment), current_risk_geos)
    
    # Count the number of flood areas within each buffered UPRN
    count_per_uprn <- lengths(uprns_in_risk)
    
    # Create a data.table which stores the final result
    count_data <- data.table(id = uprn_cm_sp$UPRN, flood_risk = count_per_uprn)
    
    # Revise count per UPRN into a binary
    count_data$flood_risk[count_data$flood_risk > 1] <- 1
    
    # Save the count data to a file
    output_file <- paste("output_file_", risk_type, ".csv", sep = "")
    fwrite(count_data, file = output_file)
    
    # Remove unnecessary objects to save memory
    rm(uprns_in_risk, count_per_uprn, count_data, current_risk_geos)
  }
  
  # Tidy
  rm(current_segment)
  
}

# Tidy
rm(surface_cm, rfrs, uprn_cm_sp, current_risk_indices, risk_type, risk_types, segment_id, segments)
gc()

# Load processed files to check have worked
output <- fread("C:/Users/mgreen/Google Drive/Papers/GroundsWell/WP4/Flooding/output_file_High.csv")
table(output$flood_risk)
output <- fread("C:/Users/mgreen/Google Drive/Papers/GroundsWell/WP4/Flooding/output_file_Medium.csv")
table(output$flood_risk)
output <- fread("C:/Users/mgreen/Google Drive/Papers/GroundsWell/WP4/Flooding/output_file_Low.csv")
table(output$flood_risk)
output <- fread("C:/Users/mgreen/Google Drive/Papers/GroundsWell/WP4/Flooding/output_file_Very Low.csv")
table(output$flood_risk)
rm(output)


## Create combined file for all indicators

# Load files
surface <- fread("C:/Users/mgreen/Google Drive/Papers/GroundsWell/WP4/Flooding/output_file_surface_flood.csv") # Surface water flooding

rfrs_high <- fread("C:/Users/mgreen/Google Drive/Papers/GroundsWell/WP4/Flooding/output_file_High.csv") # Rivers and seas flooding risk - high
names(rfrs_high)[names(rfrs_high) == "flood_risk"] <- "rivers_sea_flood_risk_high" # Rename variable

rfrs_medium <- fread("C:/Users/mgreen/Google Drive/Papers/GroundsWell/WP4/Flooding/output_file_Medium.csv") # Rivers and seas flooding risk - medium
names(rfrs_medium)[names(rfrs_medium) == "flood_risk"] <- "rivers_sea_flood_medium" # Rename variable

rfrs_low <- fread("C:/Users/mgreen/Google Drive/Papers/GroundsWell/WP4/Flooding/output_file_Low.csv") # Rivers and seas flooding risk - low
names(rfrs_low)[names(rfrs_low) == "flood_risk"] <- "rivers_sea_flood_risk_low" # Rename variable

rfrs_verylow <- fread("C:/Users/mgreen/Google Drive/Papers/GroundsWell/WP4/Flooding/output_file_Very Low.csv") # Rivers and seas flooding risk - veyr low
names(rfrs_verylow)[names(rfrs_verylow) == "flood_risk"] <- "rivers_sea_flood_very_low" # Rename variable

# Merge into a single file
all_data <- merge(surface, rfrs_high, by = "id")
all_data <- merge(all_data, rfrs_medium, by = "id")
all_data <- merge(all_data, rfrs_low, by = "id")
all_data <- merge(all_data, rfrs_verylow, by = "id")
names(all_data)[names(all_data) == "id"] <- "UPRN" # Rename variable

# Save
write.csv(all_data, "./uprn_flood_risk.csv")
rm(surface, rfrs_high, rfrs_medium, rfrs_low, rfrs_verylow, all_data)
gc()



