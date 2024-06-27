# Accessibility metrics

The README is still under construction, apologies.

## Introduction

The methods presented here estimate the road network accessibility between origin locations (households in our case) and sites of interest (e.g., green spaces). A key metric developed using this methodology is the time/distance of a household to its nearest green space, although it can be easily adapted for any particular environmental feature (e.g., replacing green spaces with General Practivec locations or retail outlets) or region/country. All of the data and methods used are open source. 

The code and methods started life as version 3 of the [Access to Healthy Assets and Hazards](https://github.com/ESRC-CDRC/ahah) resource and later refined in the [UK routes](https://github.com/cjber/ukroutes) resource. A lot of credit therefore should be given to [Cillian Berragan](https://github.com/cjber) for leading on the development of these resources which underpin the methodology presented here.

## Data

There are three key sources of information required:

### 1. Road network

The [Ordnance Survey Open Roads](https://www.ordnancesurvey.co.uk/products/os-open-roads) resource was used to act as the network to estimate the accessibility between origins and destinations (data downloaded on 4th June 2024). The resource is vector file containing the entire road network for Great Britain, including information about the nature of a road (e.g., speed limit, type of road). The resource is set up to represent lines and nodes (connections between different lines, such as junctions). While we could have used Open Street Map data here, we have found that this resource has more accurate road speed networks. 

The resource does not include routes available via ferrys which can be an important transport network when living on a remote island (especially for Scotland, although less relevant for Cheshire and Merseyside here). Ferry routes were accessed from [Open Street Map](http://overpass-turbo.eu/?q=LyoKVGhpcyBoYcSGYmVlbiBnxI1lcmF0ZWQgYnkgdGhlIG92xJJwxIlzLXR1cmJvIHdpemFyZC7EgsSdxJ9yaWdpbmFsIHNlxLBjaMSsxIk6CsOiwoDCnHJvdcSVPWbEknJ5xYjCnQoqLwpbxYx0Ompzb25dW3RpbWXFmzoyNV07Ci8vxI_ElMSdciByZXN1bHRzCigKICDFryBxdcSSxJrEo3J0IGZvcjogxYjFisWbZcWPxZHFk8KAxZXGgG5vZGVbIsWLxY1lIj0ixZByxZIiXSh7e2LEqnh9fSnFrcaAd2F5xp_GocSVxqTGpsaWxqrGrMauxrDGssa0xb_FtWVsxJRpxaDGusaTxr3Gp8apxqvGrcavb8axxrPFrceFxoJwxLduxorFtsW4xbrFvMWbxJjGnHnFrT7Frcejc2vHiMaDdDs&c=BH1aTWQmgG). 

The road network files are stored in `data/raw/oproad`.

### 2. Origins

The origin locations are our inputs for which we want to estimate the nearest distance/time to an object of interest. In our code here, the interest is on households which we define using the Unique Property Reference Number (UPRN). UPRNs are unique identifers for all unique properties across Great Britain. Data were downloaded on 4th June 2024 using [Office for National Statistic’s open UPRN directory](https://geoportal.statistics.gov.uk/datasets/acd0dbf73c2849f2a45e15c4aa248805/about). The resource is based of Ordnance Survey’s ‘AddressBase’ data product and incldues a list of all UPRNs and their geographical location (Geographic Reference System: OSGB 1936, 27700). 

The population of interest for our metric is Cheshire and Merseyside. An additional [ONS lookup table](https://geoportal.statistics.gov.uk/datasets/02d709e510804d67b16068b037cd72e6/about) linked to each UPRN was used to subset only UPRNs that fall within the Local Authorities of Cheshire and Merseyside (Chester and Cheshire East, Cheshire West, Halton, Knowsley, Liverpool, Sefton, St. Helens, Warrington and Wirral). If you wanted to recreate our indicators for a different region, one would have change this step in the code. 

The methods described below are computationally intensive and the density of UPRNs bring their own challenges (especially compared to postcodes). To improve the time spent processing UPRNs, we initially compute access metrics for [Topographic Identifiers](https://www.ordnancesurvey.co.uk/products/os-open-toid) (TOIDs) rather than UPRNs. UPRNs are nested within TOIDs, since UPRNs will give each unique property and TOIDs give the unique building. For example, a tower block or student halls accomodation will have many UPRNs for the same TOID/building (e.g., Crown Place student halls at the University of Liverpool (UK) has ~1200 UPRNs for a single TOID). Through using TOIDs, we reduce the number of computations on the assumption that they will be similar for all UPRNs (note: there will be some small differences where TOIDs have multiple entrances, but the differences should be small). We estimate for TOIDs first, then link TOID values to UPRN using an [Ordnance Survey lookup table](https://www.ordnancesurvey.co.uk/products/os-open-linked-identifiers). If you are using the code for smaller regions of UPRNS, then you may not need to do this.

Files are stored in the folder `data/raw/onspd`.

### 3. Destinations

Destinations refers to the specific features of interest that we are interested in estimating the nearest distance/time to for each origin. The data described here are therefore flexible to the specific indicator one wants to create. As such, this section will be updated as and when new accessibility indicators are created. 

#### 3a. Green space

[Ordnance Survey's Open Green Space Layer](https://www.ordnancesurvey.co.uk/products/os-open-greenspace) resource was used to capture the locations of green spaces. The resource covers Great Britain, although we subset only green spaces for Cheshire and Merseyside in our analysis here. 

The routing algorithm described below expects point locations. We therefore use the access points of each green space when estimating accessibility. Access points are the specific locations in which individuals can enter a green space (e.g., gate, road entry point). The resource also includes polyons of the spatial extent of each green space. Using these polyons, the size of each green space is calculated and alongside the type of green space (i.e., function) are joined onto the access points file so that we can differentiate between different types of green spaces.

Using the resource, we recreate the following indicators based on Natural England's 2023 Green Infrastructure Framework definitions (see p33 of their [Green infrastructure standards report](https://designatedsites.naturalengland.org.uk/GreenInfrastructure/downloads/Green%20Infrastructure%20Standards%20for%20England%20Summary%20v1.1.pdf)):
* Doorstop green space - minimum size 0.5 ha, maximum distance 200 m, maximum journey time 5 minutes (walk).
* Local green space - minimum size 2 ha, maximum distance 300 m, maximum journey time 5 minutes (walk).
* Neighbourhood green space - minimum size 10 ha, maximum distance 1 km, maximum journey time 15 minutes (walk).
* Wider green space - minimum size 20 ha, maximum distance 2 km, maximum journey time 35 minutes (walk).
* District ogreen space - minimum size 100 ha, maximum distance 5 km, maximum journey time 15-20 minutes (cycle).
* Sub-regional green space - minimum size 500 ha, maximum distance 10 km, maximum journey time 30-40 minutes (cycle).

Files are stored in the folder `data/raw/osgsl`.

## Methods

The core methodology involves estimating the single source shortest path algorithm for every UPRN. We have found since developing the Access to Healthy Assets and Hazards resource that computing road network accessibility measures is cimputationally intensive. We have improved this methodology through using the GPU accelerated Python library `cugraph`, part of the [NVIDIA RAPIDS ecosystem](https://rapids.ai/). `cugraph` allows for the highly parrallised processing of graph networks. This has significantly reduced the computational time from days to hours or minutes (depending on the size of the dataset).

To run the code, you will need access to GPU support (the larger, the better). If you do not have access to a GPU, then I have created a jupyter notebook so that you can run the code in [Google Colab](https://colab.research.google.com/) which can provide you with free access to cloud GPU support (see `colab_nb.ipynb`). It takes roughly one hour to run the notebook using the premium Colab option and after the roads have been pre-processed (this only needs to be done once, so it is therefore one hour per indicator). The notebook includes how to set up Google Colab to run the repo. 

I have divided the specific details of how the methods work into two stages below.

### 1. Preprocessing

The first step is to wrangle the raw input data into the neccessary formats for estimating the routing paths. There are two key files that you will need to run seperately:

#### 1a. Road network

The file `ukroutes/preprocessing.py` processes the road network into a graph network and estimates the time taken inbetween the segments of the road network (edges). 

1. `process_road_edges`: The function reads road link data and calculates time estimates for road segments based on the speed estimates included in the dataset (estimated based on road classification and form). The speed estimates (in km/h) are converted to time estimates (in minutes) based on the length of each road segment. The processed data is returned as a Polars DataFrame containing the start and end nodes, time estimates, and lengths of the road segments.
2. `process_road_nodes`: The function processes road node data, extracting the easting and northing coordinates from the geometry of the nodes. It returns a Polars DataFrame with the node IDs and their coordinates.
3. `ferry_routes`: The function takes ferry routes data and links each ferry node with the nearest road nodes using a KDTree for efficient nearest-neighbor queries. The function calculates time estimates for ferry edges based on their lengths and a fixed speed estimate. The processed ferry nodes and edges are returned as Polars DataFrames.
4. `process_os`: This function orchestrates the overall processing workflow through processing the input data using the three functions described above. The nodes are re-indexed to ensure unique identifiers, and the final nodes and edges DataFrames are saved to parquet files for efficient storage and retrieval.

The code will process the entire road network for Great Britain. While we could have subset the network for just Cheshire and Merseyside to save time, it is not too long to do Great Britain as a whole so we left it as that for now. The resulting processed road network is stored in the folder `routes/routes/osm`.

The file only needs processing once and it can then be used for any additional indicator generation

#### 1b. Origins and destinations

The file `ukroutes/process_input_files.R` processes all origin and destintion datasets into the formats that they require for being used in the routing calculations.

First, it loads in all UPRNs for Great Britain and subsets only those located in Cheshire and Merseyside. Second, the green space dataset is loaded in. Rather than just subsetting only green spaces that are located in Cheshire and Merseyside, we use this spatial extent plus a buffer of 1km around it to minimise any edge effects in the computation of accessibility (i.e., where the nearest green space lies just over the region border, this would be missed by subsetting on just the region). 

The R file will be updated as and when we add new destination indicators to be processed.

### 2. Estimate routing

The script `ukroutes/routing.py` does the following:
* Imports and Warnings: The script starts by importing necessary libraries, including cuDF and cuGraph for GPU-accelerated data processing, GeoPandas for geospatial data manipulation, and other utility modules from the ukroutes package. It also suppresses future warnings from cuGraph to avoid excessive warnings.
* Greenspace Data: Reads greenspace data from a Parquet file.
* Preprocessed Nodes and Edges: Loads previously processed road network nodes and edges from Parquet files and converts them to cuDF DataFrames for GPU processing.
* The filter_deadends function constructs a graph using the loaded edges, identifies connected components, and filters out nodes and edges that are not part of the largest connected component. This step ensures the graph is contiguous and removes isolated nodes and edges.
* Integrating Additional Data: The add_to_graph function is used to integrate greenspace data and postcode data into the graph, updating the nodes and edges accordingly. The add_topk function is applied to rank and possibly filter the greenspace and postcode data based on proximity or another metric.
* Routing Calculation: A Routing object is instantiated with the processed nodes, edges, greenspace areas (as inputs), and postcodes (as outputs). The routing object is configured with parameters such as weights (time estimates) and buffer distances. The fit method of the Routing object calculates distances between nodes in the graph based on the given weights and buffers.
* Saving Results: The computed distances are joined with the postcode data to associate each distance with a specific postcode.The resulting DataFrame, containing postcodes and distances, is saved to a CSV file.
* The process_ev function is commented out because its functionality was already executed elsewhere. Some code sections related to further processing and data handling (e.g., dropna, additional filtering) are also commented out, indicating they may be optionally included depending on the use case. 
* Paths Module: The Paths module from ukroutes.common.utils provides paths to various input and output data files, ensuring consistent file handling across the script.
* Routing Class: Part of the ukroutes package, this class is responsible for setting up and performing the routing computations. The configuration includes specifying the edges, nodes, input and output datasets, and the criteria for calculating distances (e.g., time-weighted travel).

One can measure either the shortest distance or time from a household to any indicator of interest (e.g., nearest green space). Currently the code is set up to estimate the shortest time. If you want to change the output to record distance, please change the parts of the code that say "time_weighted" to "distance" (see). 

## Examples of usage

Through estimating the accesibility of each household to their nearest green space, one can investigate how the living closer or far from these spaces influences human activity (e.g., physical activity), health and wellbeing outcomes. This can help us to generate evidence on the importance of building or maintaining natural environments. 
