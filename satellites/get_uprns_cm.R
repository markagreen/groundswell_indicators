#########################
### Get UPRNs for C&M ###
#########################


## Aim: To subset all UPRNs for Cheshire and Merseyside

# Libraries
library(data.table)
library(arrow)

# Load UPRNs
uprn <- fread("./osopenuprn_202405_csv/osopenuprn_202405.csv") # All UPRNs for GB and their points, then load the following April 2024 data via https://geoportal.statistics.gov.uk/datasets/acd0dbf73c2849f2a45e15c4aa248805/about - gives UPRN IDs and their locational information (exact point)
uprn_lkup <- fread("./NSUL_APR_2024_NW.csv") # This is a lookup file linking the UPRNs to spatial identifiers for the North West UPRNs for April 2024 https://geoportal.statistics.gov.uk/datasets/02d709e510804d67b16068b037cd72e6/about 
uprn_lkup <- merge(uprn_lkup, uprn, by = "UPRN", all.x = TRUE) # Join on exact locations to NW dataset
rm(uprn)

# Subset only Cheshire and Merseyside
uprn_cm <- uprn_lkup[uprn_lkup$lad23cd == "E06000049" | uprn_lkup$lad23cd == "E06000050" | uprn_lkup$lad23cd == "E06000006" | uprn_lkup$lad23cd == "E08000011" | uprn_lkup$lad23cd == "E08000012" | uprn_lkup$lad23cd == "E08000014" | uprn_lkup$lad23cd == "E08000013" | uprn_lkup$lad23cd == "E06000007" | uprn_lkup$lad23cd == "E08000015",] # Local Authority Codes in order are: Cheshire East, Cheshire West and Chester, Halton, Knowsley, Liverpool, Sefton, St Helens, Warrington, Wirral
rm(uprn_lkup)

# Edit variables to keep those needed
names(uprn_cm)[names(uprn_cm) == "LATITUDE"] <- "latitude"
names(uprn_cm)[names(uprn_cm) == "LONGITUDE"] <- "longitude"
uprn_cm <- uprn_cm[, c("UPRN", "latitude", "longitude")] # drop variables not required
uprn_cm <- uprn_cm[!is.na(uprn_cm$latitude)] # Drop missing data (76 with missing locations)
write_parquet(uprn_cm, "./uprns_cm.parquet") # Save
rm(uprn_cm)
gc()

