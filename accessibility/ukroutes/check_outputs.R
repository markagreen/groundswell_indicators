#####################
### Check outputs ###
#####################

# Aim: To check that the generated metrics look robust.

# Libraries
library(data.table)
library(ggplot2)
library(viridis)
library(sf)

## 1. Green space data

# Load data
gsp <- fread("C:/Users/mgreen/Google Drive/Colab/ukroutes/data/out/distances_greenspace_uprn.csv") 
names(gsp)[names(gsp) == "postcode"] <- "UPRN" # Rename

# Inspect data
summary(gsp) # Get summary stats

# Work out how many 0
gsp$zero <- 0 
gsp$zero[gsp$distance == 0] <- 1
table(gsp$zero)

# Map the values

# Aggregate data to LSOAs
uprn_lkup <- fread("C:/Users/mgreen/Google Drive/Colab/ukroutes/data/raw/onspd/NSUL_APR_2024/Data/NSUL_APR_2024_NW.csv") # Get spatial area lookup files
test <- merge(gsp, uprn_lkup, by = "UPRN", all.x = TRUE) # Merge to UPRNs
uprn_lsoas <- test[, list(mean_distance = mean(distance, na.rm = TRUE)), by = "lsoa21cd"] # Aggregate to LSOAs

# Get LSOA boundaries for region
lsoas_eng <- read_sf("C:/Users/mgreen/Google Drive/Colab/ukroutes/spatial_files/Lower_layer_Super_Output_Areas_2021_EW_BFC_V8_4078143405809415814.gpkg") # Load
lsoas_eng$name_short <- substr(lsoas_eng$LSOA21NM, 1, 5)
lsoas_cm <- lsoas_eng[lsoas_eng$name_short == "Chesh" | lsoas_eng$name_short == "Chest" | lsoas_eng$name_short == "Halto" | lsoas_eng$name_short == "Knows" | lsoas_eng$name_short == "Liver" | lsoas_eng$name_short == "Sefto" | lsoas_eng$name_short == "St. H" | lsoas_eng$name_short == "Warri" | lsoas_eng$name_short == "Wirra",] # Subset Cheshire and Merseyside
lsoas_cm$name_short <- substr(lsoas_cm$LSOA21NM, 1, 12) # The above gives Chesterfield too so need to leave out
lsoas_cm <- lsoas_cm[lsoas_cm$name_short != "Chesterfield",] # Drop Chesterfield
lsoas_cm$name_short <- NULL # Delete variable
write_sf(lsoas_cm, "C:/Users/mgreen/Google Drive/Colab/ukroutes/spatial_files/cm_lsoas.shp") # this includes chesterfield so need to drop
rm(lsoas_eng)

# Join together
lsoas_cm <- merge(lsoas_cm, uprn_lsoas, by.x = "LSOA21CD", by.y = "lsoa21cd", all.x = TRUE)

# Plot
ggplot() +
  geom_sf(data = lsoas_cm, aes(fill = mean_distance), color = NA) +
  scale_fill_viridis(trans = "sqrt")
