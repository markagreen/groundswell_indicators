# Methodology for creating a Unique Property Reference Number (UPRN) flood risk indicator

## Introduction

This readme details the creation of a lookup table for identifying whether a Unique Property Reference Numbers (UPRN) is located in an area at risk of flooding. The measures developed here cover the three main flooding risks in the UK: fluvial (rivers and streams), coastal and surface water. We selected these risks and how best to measure them following consultation with Dr Charlotte Lydon and Professor Neil Macdonald who are experts in these processes. 

## Data

The following open data sources were used as inputs in the creation of these methods:
* Unique Property Reference Number (UPRN) was accessed using [Office for National Statistic’s open UPRN directory](https://geoportal.statistics.gov.uk/datasets/acd0dbf73c2849f2a45e15c4aa248805/about). UPRNs are unique identifers for all unique properties across Great Britain. The dataset was the latest available at the time of access and refers to all UPRNs as at April 2024. The resource is based of Ordnance Survey’s ‘AddressBase’ data product and incldues a list of all UPRNs and their geographical location (Geographic Reference System: OSGB 1936, 27700). We further use an [ONS lookup table](https://geoportal.statistics.gov.uk/datasets/02d709e510804d67b16068b037cd72e6/about) linked to each UPRN to subset only UPRNs that fall within the Local Authorities of Cheshire and Merseyside. These data were downloaded on 4th June 2024.
* Surface water flooding risk areas were defined using the Environment Agency’s [‘blue square map’ resource](https://www.data.gov.uk/dataset/7792054a-068d-471b-8969-f53a22b0c9b2/indicative-flood-risk-areas-shapefiles). The data are generated as part of Environment Agency’s legal duties under the flood risk regulations. They identify 1x1km gridded cells that defined areas at risk of surface flooding under 1 in 100 and 1 in 1000 high rainfall events. The resource is generated for the whole of England. Data for the whole of England were downloaded on 7th June 2024 and represent the latest version of the dataset (last updated 14th June 2024).
* Areas at risk of flooding from rivers and seas were defined using the Environment Agency’s [‘Risk of Flooding from Rivers and Seas’ resource](https://environment.data.gov.uk/dataset/8d57464f-d465-11e4-8790-f0def148f590). The resource is the main national level (England only) resource for flood risk mapping. It is a 50x50m gridded cell definition of flooding risk from rivers and seas, defining cells on a scale from very low to high based on the number and quality of flood defences in each cell. More information about the methodology can be viewed [here](https://environment.data.gov.uk/api/file/download?fileDataSetId=d1651d70-29a8-406a-8e66-cdf15a11ef23&fileName=RoFRS_Product_Description_v2_3.pdf). Data were downloaded on 10th June 2024. The resource asks one to download data by defining a bounding box and therefore multiple manual requests were undertaken to download the Cheshire and Merseyside region. Following a formal request to the Environment Agency, they later supplied the national level dataset. The resource was [paused](https://www.gov.uk/guidance/updates-to-national-flood-and-coastal-erosion-risk-information#:~:text=Pause%20to%20regular%20updates%20of%20flood%20risk%20data,-The%20Environment%20Agency&text=We%20are%20also%20using%20this,last%20updated%201%20November%202023) so that it could be improved and last updated on 6th December 2023 (new version due end of 2024). We will update our indicator once the latest version is available. 

While our data here only refers to the Cheshire and Merseyside Integrated Care Board region (defined here as the Local Authorities: Chester and Cheshire East, Cheshire West, Halton, Knowsley, Liverpool, Sefton, St. Helens, Warrington and Wirral), the data and methods can easily be adapted for any other region or nation.   

## Methods

The following steps were undertaken:
1. Load in each dataset and clean them into analysis ready versions.
2. Use an efficient spatial join operation to identify if a UPRN is located within a food risk zone. Repeat this process for each individual indicator and save them.
3. Combine each indicator into a single Comma Separated Values (CSV) file to output. 

The output from this process is a single file where each row represents an UPRN (including its unique identifier number) and a series of binary columns representing if the UPRN is located within a flood risk area for that specific measure. The file has the following columns:
* UPRN - unique identifier for a UPRN.
* surface_flood_risk - is the UPRN located in an area at risk of surface flooding as defined by the Environment Agency’s blue map resource (0 = no, 1 = yes).
* rivers_sea_flood_very_low - is the UPRN located within a ‘high’ flood risk area as defined by the Environment Agency’s ‘risk of flooding from rivers and seas’ resource (0 = no, 1 = yes).
* rivers_sea_flood_very_low - is the UPRN located within a ‘high’ flood risk area as defined by the Environment Agency’s ‘risk of flooding from rivers and seas’ resource (0 = no, 1 = yes).
* rivers_sea_flood_very_low - is the UPRN located within a ‘high’ flood risk area as defined by the Environment Agency’s ‘risk of flooding from rivers and seas’ resource (0 = no, 1 = yes).
* rivers_sea_flood_very_low - is the UPRN located within a ‘high’ flood risk area as defined by the Environment Agency’s ‘risk of flooding from rivers and seas’ resource (0 = no, 1 = yes).

The R code to replicate the indicator can be openly accessed in this repo. One should run the file [flood_risk_indicator_uprn.R] to create the indicators (https://github.com/markagreen/groundswell_indicators/blob/main/flood%20risk/flood_risk_indicator_uprn.R). It takes just under two hours to run on our local machine (CPU 3.20 GHZ, 32 GB RAM). The spatial join process is computationally intensive and slow with a large dataset like UPRNs. Speed improvements could be gained through using [Topographic Identifiers](https://www.ordnancesurvey.co.uk/products/os-open-toid) (TOIDs) rather than UPRNs (then linking TOIDs to UPRNs), as well as simplifying the flood risk inputs. 

## Examples of usage

Linking the flooding indicators described here to individual-level electronic health care records via UPRNs will allow the description of the health issues facing communities at risk of flooding. UPRNs can also be aggregated to administrative zones to match them to information about the demographic and socioeconomic characteristics of communities to profile who is at risk (e.g., are UPRNs in more deprived areas more at risk of flooding than those in less deprived areas). 



