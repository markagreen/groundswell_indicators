# Satellite derived green and blue space indicators

## Introduction

The purpose of this repo is to estimate the following indicators of green and blue spaces for each household, as defined as the Unique Property Reference Number (UPRN), across Cheshire and Merseyside:

* Normalised Difference Vegetation Index (NDVI)
* Enhanced Vegetation Index (EVI)
* Normalised Difference Water Index (NDWI)

The indicators are generated using remote sensing / satellite imagery. They are based on 300 meter buffers around each UPRN (i.e., to represent the broader area characteristics since one pixel may capture only the roof of a building), although one can change the size of the buffer during the process. 

## Data

There are two key data sources used here: (1) Household locations, and (2) Satellite imagery.

### Household locations

The target household identifiers that we want to compute the indicators for are Unique Property Reference Numbers (UPRNs). UPRNs are unique identifiers for all unique properties across Great Britain. Data were downloaded on 4th June 2024 using [Office for National Statistic’s open UPRN directory](https://geoportal.statistics.gov.uk/datasets/acd0dbf73c2849f2a45e15c4aa248805/about). The resource is based on Ordnance Survey’s ‘AddressBase’ data product and includes a list of all UPRNs and their geographical location (Geographic Reference System: OSGB 1936, 27700). 

The population of interest for our metric is Cheshire and Merseyside. An additional [ONS lookup table](https://geoportal.statistics.gov.uk/datasets/02d709e510804d67b16068b037cd72e6/about) linked to each UPRN was used to subset only UPRNs that fall within the Local Authorities of Cheshire and Merseyside (Cheshire East, Cheshire West and Chester, Halton, Knowsley, Liverpool, Sefton, St. Helens, Warrington and Wirral). If you wanted to recreate our indicators for a different region, one would have to change this step in the code. 

Using UPRNs makes the code computationally intensive and results in very large file sizes (especially once we calculate buffers for each point). To improve the time spent processing UPRNs, we initially compute the metrics for [Topographic Identifiers (TOIDs)](https://www.ordnancesurvey.co.uk/products/os-open-toid) rather than UPRNs. UPRNs are nested within TOIDs, since UPRNs will give each unique property and TOIDs give the unique building. For example, a tower block or student halls accommodation will have many UPRNs for the same TOID/building (e.g., Crown Place student halls at the University of Liverpool (UK) has ~1200 UPRNs for a single TOID). Through using TOIDs, we reduce the number of computations on the assumption that they will be similar for all UPRNs (note: there will be some small differences where TOIDs have multiple entrances, but the differences should be negligible here). The result is that using TOIDs gives us a dataset which is 23% smaller than if we use UPRNs only. In the workflow described below, we first estimate each indicator for TOIDs within Cheshire and Merseyside (using the datasets described above), then link the TOID values back to UPRNs using an [Ordnance Survey lookup table](https://www.ordnancesurvey.co.uk/products/os-open-linked-identifiers). If you are using the code for smaller regions of UPRNS, then you may not need to do this.

### Satellite imagery

We use [Sentinel-2](https://www.esa.int/Applications/Observing_the_Earth/Copernicus/Sentinel-2) imagery to estimate green and blue space metrics. Sentinel-2 is a satellite which has been providing remote sensing imagery data since 28th March 2017 and was selected since it has the highest resolution (10 meters) of all the available open satellite datasets. One accesses Sentinel-2 data via [Google Earth Engine](https://earthengine.google.com/) which is free to access for academic and not-for-profit organisations.  

Working with satellite imagery brings its own challenges. Great Britain is a temperate climate that offers frequent cloudy or overcast days. To try and minimise this issue, we mask any detected clouds within the images so that they do not count towards the generation of indicators (since cloud values will give misleading estimates). A composite image is then compiled by taking the median value across the whole time period. If we wanted to take this further, we could have only used images where <= 20% of the image does not contain clouds too. To create 2024 data here, we have used the time period of 1st January 2024 to 2nd July 2024 - our plan is to get the code to be finished first and then later change this time period once we are later in the year. The final dates will be chosen to capture the spring/summer period where vegetation has grown and as it is peak, as well as to maximise the time period available to find suitable non-cloudy days of images. Once can easily adapt this time period in the code to what they need. 

## Methodology

There are three files required for the generation of the indicators:

1. `get_uprns_cm.R` should be run first. The R file loads the household datasets and cleans them into the neccessary format for the next step. One could integrate this into the file below for a more efficient set up. The file should take ~5 minutes to run locally. 
2. `green_space_sentinel2.ipynb` is a Jupuyter notebook which is designed to run in the cloud using [Google Colab](https://colab.research.google.com/). It is written in Python. The file will load the cleaned UPRNs from the previous step, set up access to Sentinel-2 images in Google Earth Engine, generate 300 meter buffers around UPRNs, and then calculate the average (mean) values for NDVI, EDI and NWDI within each buffer. The notebook will take longer to run (~1 hour).
3. `check_toids.R` is the final file to run. It compiles all of the processed indicators for each Local Authority, combines them into a single file that will be linked and checks the quality of the estimates. 

## Examples of usage

The indicators generate measures of 'greenness' and 'blueness' of the environments surrounding households. These data can be linked to electronic health records to investigate whether people who reside in 'greener' or 'bluer' areas have better health or wellbeing. 
