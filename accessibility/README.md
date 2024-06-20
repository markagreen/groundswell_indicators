# Accessibility metrics

## Introduction

The methods presented here estimate the road network accessibility between origin locations (households in our case) and sites of interest (e.g., green spaces). A key metric developed using this methodology is the time/distance of a household to its nearest green space, although it can be easily adapted for any particular environmental feature (e.g., replacing green spaces with General Practivec locations or retail outlets) or region/country. All of the data and methods used are open source. 

The code and methods started life as version 3 of the [Access to Healthy Assets and Hazards](https://github.com/ESRC-CDRC/ahah) resource and later refined in the updated [UK routes](https://github.com/cjber/ukroutes) resource. A lot of credit therefore should be given to [Cillian Berragan](https://github.com/cjber) for leading on the development of these resources which underpin the methodology presented here.

## Data

There are three key sources of information required:

### 1. Road network

The [Ordnance Survey Open Roads](https://www.ordnancesurvey.co.uk/products/os-open-roads) resource was used to act as the network to estimate the accessibility between origins and destinations (data downloaded on 4th June 2024). The resource is vector file containing the entire road network for Great Britain, including information about the nature of a road (e.g., speed limit, type of road). The resource is set up to represent lines and nodes (connections between different lines, such as junctions). 

The road network files are stored in `data/raw/oproad`.

### 2. Origins

The origin locations are our inputs for which we want to estimate the nearest distance/time to an object of interest. In our code here, the interest is on households which we define using the Unique Property Reference Number (UPRN). UPRNs are unique identifers for all unique properties across Great Britain. Data were downloaded on 4th June 2024 using [Office for National Statistic’s open UPRN directory](https://geoportal.statistics.gov.uk/datasets/acd0dbf73c2849f2a45e15c4aa248805/about). The resource is based of Ordnance Survey’s ‘AddressBase’ data product and incldues a list of all UPRNs and their geographical location (Geographic Reference System: OSGB 1936, 27700). 

The population of interest for our metric is Cheshire and Merseyside. An additional [ONS lookup table](https://geoportal.statistics.gov.uk/datasets/02d709e510804d67b16068b037cd72e6/about) linked to each UPRN was used to subset only UPRNs that fall within the Local Authorities of Cheshire and Merseyside (Chester and Cheshire East, Cheshire West, Halton, Knowsley, Liverpool, Sefton, St. Helens, Warrington and Wirral). If you wanted to recreate our indicators for a different region, one would have change this step in the code. 

The methods described below are computationally intensive and the density of UPRNs bring their own challenges (especially compared to postcodes). To improve the time spent processing UPRNs, we initially compute access metrics for [Topographic Identifiers](https://www.ordnancesurvey.co.uk/products/os-open-toid) (TOIDs) rather than UPRNs. UPRNs are nested within TOIDs, since UPRNs will give each unique property and TOIDs give the unique building. For example, a tower block or student halls accomodation will have many UPRNs for the same TOID/building (e.g., Crown Place student halls at the University of Liverpool (UK) has ~1200 UPRNs for a single TOID). Through using TOIDs, we reduce the number of computations on the assumption that they will be similar for all UPRNs (note: there will be some small differences where TOIDs have multiple entrances, but the differences should be small). We estimate for TOIDs first, then link TOID values to UPRN using an [Ordnance Survey lookup table](https://www.ordnancesurvey.co.uk/products/os-open-linked-identifiers). If you are using the code for smaller regions of UPRNS, then you may not need to do this.

Files are stored in the folder `data/raw/onspd`.

### 3. Destinations

Destinations refers to the specific features of interest that we are interested in estimating the nearest distance/time to for each origin. The data described here are therefore flexible to the specific indicator one wants to create. As such, this section will be updated as and when new accessibility indicators are created. 

#### 3a. Green space

[Ordnance Survey's Open Green Space Layer](https://www.ordnancesurvey.co.uk/products/os-open-greenspace) resource was used to .

Files are stored in the folder `data/raw/osgsl`.

## Methods

One can measure either the shortest distance or time from a household to any indicator of interest (e.g., nearest green space). 

To run the code, you will need access to GPU support (the larger, the better). . It takes roughly one hour to run the notebook once the roads have been pre-processed (this only needs to be done once, so it is therefore one hour per indicator). 

#### 1. Preprocessing

A

#### 2. Estimate routing

A

## Examples of usage

Through estimating the accesibility of each household to their nearest green space, one can investigate how the living closer or far from these spaces influences human activity (e.g., physical activity), health and wellbeing outcomes. This can help us to generate evidence on the importance of building or maintaining natural environments. 
