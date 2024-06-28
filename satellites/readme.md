# Satellite derived green and blue space indicators

## Introduction

The purpose of this repo is to estimate the following indicators of green and blue spaces for each household, as defined as the Unique Property Reference Number (UPRN), across Cheshire and Merseyside:

* Normalised Difference Vegetation Index (NDVI)
* Enhanced Vegetation Index (EVI)
* Normalised Water Difference Index (NWDI)

The indicators are generated using remote sensing / satellite imagery. They are based on 300 meter buffers around each UPRN (i.e., to represent the broader area characteristics since one pixel may capture only the roof of a building), although one can change the size of the buffer during the process. 

## Data

There are two key data sources used here.

Firstly, Unique Property Reference Numbers (UPRNs) are used to represent individual households. UPRNs are unique identifers for all unique properties across Great Britain. Data were downloaded on 4th June 2024 using [Office for National Statistic’s open UPRN directory](https://geoportal.statistics.gov.uk/datasets/acd0dbf73c2849f2a45e15c4aa248805/about). The resource is based on Ordnance Survey’s ‘AddressBase’ data product and includes a list of all UPRNs and their geographical location (Geographic Reference System: OSGB 1936, 27700). 

The population of interest for our metric is Cheshire and Merseyside. An additional [ONS lookup table](https://geoportal.statistics.gov.uk/datasets/02d709e510804d67b16068b037cd72e6/about) linked to each UPRN was used to subset only UPRNs that fall within the Local Authorities of Cheshire and Merseyside (Chester and Cheshire East, Cheshire West, Halton, Knowsley, Liverpool, Sefton, St. Helens, Warrington and Wirral). If you wanted to recreate our indicators for a different region, one would have change this step in the code. 

Secondly, we use [Sentinel-2](https://www.esa.int/Applications/Observing_the_Earth/Copernicus/Sentinel-2) imagery to estimate green and blue space metrics. Sentinel-2 is a satellite which has been providing remote sensing imagery data since 28th March 2017 and was selected since it has the highest resolution (10 meters) of all the available open satellite datasets. One accesses Sentinel-2 data via [Google Earth Engine](https://earthengine.google.com/) which is free to access for academic and not-for-profit organisations.  

Working with satellite imagery brings its own challenges. Great Britain is a temperate climate that offers frequent cloudy or overcast days. Clouds block images of the ground. To try and minimise this issue, the code only uses images where <= 20% of the image contains clouds. A composite image is then compiled by taking the median value between 1st May 2023 and 30th September 2023. The dates were chosen to capture the spring/summer period where vegetation has grown and as it is peak (although one can easily change this), as well as to maximise the time period available to find suitable non-cloudy days of images. The indicator will be updated once 2024 has passed this point in the year. 

## Methodology

There are only two files required for the generation of the indicators:

1. `get_uprns_cm.R` should be run first. The R file loads the UPRN files and cleans them into the neccessary format for the next step. One could integrate this into the file below for a more efficient set up. The file should take 1-2 minutes to run locally. 
2. `green_space_sentinel2.ipynb` is a Jupuyter notebook which is designed to run in the cloud using [Google Colab](https://colab.research.google.com/). It is written in Python. The file will load the cleaned UPRNs from the previous step, set up access to Sentinel-2 images in Google Earth Engine, generate 300 meter buffers around UPRNs, and then calculate the average (mean) values for NDVI, EDI and NWDI within each buffer. 

## Examples of usage

The indicators generate measures of 'greenness' and 'blueness' of the environments surrounding households. These data can be linked to electronic health records to investigate whether people who reside in 'greener' or 'bluer' areas have better health or wellbeing. 
