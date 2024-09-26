########################################
### Processing inputs - blue spaces ###
########################################


## Aim: To create a single dataset capturing all blue spaces for Cheshire and Merseyside, estimate proxy access points, and save them in the required format for accessibility processing.

# Libraries
library(data.table)
library(arrow)
library(sf)


## Load datasets ##

# Create object for spatial extent of Cheshire and Merseyside 
ukmap <- read_sf("../spatial_files/Local_Authority_Districts_December_2023_Boundaries_UK_BFE_7168133065712352501.geojson")  # Load in all Local Authorities for UK. Downloaded from https://www.data.gov.uk/dataset/288458f7-7789-47d0-80d4-ffdf746c6b75/local-authority-districts-december-2023-boundaries-uk-bfe (25th September 2024). Mean low water mark. Generalised so not detailed - only use for cutting datasets.
ukmap <- st_transform(ukmap, crs = 27700) # Convert to OSGB1936 to match later files
cmmap <- ukmap[ukmap$LAD23NM == "Wirral" | ukmap$LAD23NM == "Warrington" | ukmap$LAD23NM == "Sefton" | ukmap$LAD23NM == "St. Helens" | ukmap$LAD23NM == "Liverpool" | ukmap$LAD23NM == "Knowsley" | ukmap$LAD23NM == "Halton" | ukmap$LAD23NM == "Cheshire West and Chester" | ukmap$LAD23NM == "Cheshire East",] # Select Cheshire and Merseyside locations
cmmap_dissolved <- st_union(cmmap) # Dissolve all boundaries so a single area extent
cmmap_buffer <- st_buffer(cmmap_dissolved, dist = 2000) # Create 2km buffer around region to minimise edge effects
rm(ukmap, cmmap, cmmap_dissolved) # Tidy

# Load Ordnance Survey Open Rivers (rivers, streams, canals)
# Note: the dataset contains the following types in C&M (see coast$form) - canal, inland river, lake  and tidal river. We could split them out further if useful
osrivers <- read_sf("../data/raw/blue_space/oprvrs_gpkg_gb/Data/oprvrs_gb.gpkg", layer = "watercourse_link") # Downloaded from https://www.ordnancesurvey.co.uk/products/os-open-rivers (24th September 2024) - GB coverage only
osrivers_cm <- st_intersection(osrivers, cmmap_buffer) # Subset only points within the spatial extent of above buffer - osgsl access points # Subset Cheshire and Merseyside extent
rm(osrivers) # Tidy

# Load CEH's open waterbodies resource (lakes, reservoirs, public ponds)
cehwater <- read_sf("../data/raw/blue_space/b6b92ce3-dcd7-4f0b-8e43-e937ddf1d4eb/b6b92ce3-dcd7-4f0b-8e43-e937ddf1d4eb/data/uklakes_v3_6_poly.gpkg") # Downloaded from https://www.data.gov.uk/dataset/899e3816-b760-4eb4-a1f1-34fc7858f705/spatial-inventory-of-uk-waterbodies (24th September 2024) - UK coverage. Last updated June 2024.
cehwater_cm <- st_intersection(cehwater, cmmap_buffer) # Subset only points within the spatial extent of above buffer - osgsl access points # Subset Cheshire and Merseyside extent
rm(cehwater) # Tidy

# Load coastline (captures sea and those related infrastructure or physical features found at the coast - piers, cliffs, beaches, harbours, marinas, docks, promenades)
oscoast <- read_sf("../data/raw/blue_space/bdline_gpkg_gb/Data/bdline_gb.gpkg", layer = "high_water") # Downloaded from https://www.ordnancesurvey.co.uk/products/boundary-line (25th September 2024) - GB coverage only. Here define the coast line as the high water extent.
oscoast_cm <- st_intersection(oscoast, cmmap_buffer) # Subset only points within the spatial extent of above buffer - osgsl access points # Subset Cheshire and Merseyside extent
rm(oscoast) # Tidy

## Convert lines into points ##

# Get variables to be consistent
osrivers_cm <- osrivers_cm[, c("geometry")] # Subset variables needed
oscoast_cm <- oscoast_cm[, c("geometry")] # Subset variables needed

# Join together both lines dataset
all_lines <- rbind(osrivers_cm, oscoast_cm) # Join together
rm(oscoast_cm, osrivers_cm) # Tidy

# Wrangle object into neccessary format to sample from
linestrings <- all_lines[st_geometry_type(all_lines) == "LINESTRING", ] # Subset just single linestrings
multilinestrings <- all_lines[st_geometry_type(all_lines) == "MULTILINESTRING", ] # Subset out those which are multilinestrings (these are the problematic ones here so need to fix)
cast_multilines <- st_cast(multilinestrings, "LINESTRING") # Convert all multilinestrings to linestrings
combined_lines <- rbind(linestrings, cast_multilines) # Create single object which is only linestrings
rm(linestrings, multilinestrings, cast_multilines)

# Convert lines to points
density <- 1 / 100 # Define how many points per meter
sampled_points <- st_line_sample(combined_lines, density = density) # Sample points every 100m
sampled_points_geom <- st_cast(st_sfc(sampled_points), "POINT") # Above gives multipoints, so cast to just points to eliminate
sampled_points_sf <- st_sf(geometry = sampled_points_geom) # Convert to sf object
rm(sampled_points, sampled_points_geom) # Tidy

## Convert polygons into access points ##

# Create points dataset
polys <- st_cast(st_geometry(cehwater_cm), "POINT", density = density) # Sample points every 100m
polys <- st_cast(polys, "POINT") 
sampled_points_sf2 <- st_sf(geometry = polys) # Convert to sf object
rm(density, polys) # Tidy


## Combine datasets into single file ##

# Join together all points
bluesp_points <- rbind(sampled_points_sf, sampled_points_sf2) # Join together  (n = 19122 access points)
rm(sampled_points_sf, sampled_points_sf2) # Tidy

# Get spatial coordinates
coordinates <- st_coordinates(bluesp_points) # Get easting and northing
coordinates_df <- as.data.frame(coordinates) # Convert the coordinates to a data frame 
colnames(coordinates_df) <- c("easting", "northing") # Rename columns
bluesp_points$easting <- coordinates_df$easting # Append the coordinates to the original object
bluesp_points$northing <- coordinates_df$northing

# Wrangle into format for saving
bluesp_points <- data.table(bluesp_points) # Convert format for saving
bluesp_points$geometry <- NULL # Delete as not required
bluesp_points$id <- 1:nrow(bluesp_points) # Add in ID variable
bluesp_points <- bluesp_points[, c("id", "easting", "northing")] # Re-order columns

# Save
write_parquet(bluesp_points, "../data/processed/bluespace/bluespace_all.parquet") # Save



