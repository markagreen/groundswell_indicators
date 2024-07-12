# Import libraries, packages and functions
import cudf
import geopandas as gpd
import numpy as np
import pandas as pd
import cugraph
import warnings

from ukroutes import Routing
from ukroutes.common.utils import Paths #, filter_deadends
from ukroutes.preprocessing import process_os
from ukroutes.process_routing import add_to_graph, add_topk

# To stop warnings being printed, which will lead to a million of them on Colab
warnings.filterwarnings("ignore", category=FutureWarning, module="cugraph")

# Load destinations
# Suggest that you load one at a time, run the script, then re-run the script again with a different one (yes lazy as easier than writing a loop or several scripts)
greenspace = pd.read_parquet(Paths.PROCESSED / "osgsl" / "osgsl_all.parquet") # All green spaces of any size / type
#greenspace = pd.read_parquet(Paths.PROCESSED / "osgsl" / "osgsl_doorstop.parquet") # Doorstop greenspace
#greenspace = pd.read_parquet(Paths.PROCESSED / "osgsl" / "osgsl_local.parquet") # Local greenspace
#greenspace = pd.read_parquet(Paths.PROCESSED / "osgsl" / "osgsl_neighbourhood.parquet") # Neighbourhood greenspace
#greenspace = pd.read_parquet(Paths.PROCESSED / "osgsl" / "osgsl_district.parquet") # District greenspace
#greenspace = pd.read_parquet(Paths.PROCESSED / "osgsl" / "osgsl_wider.parquet") # Wider greenspace
#greenspace = pd.read_parquet(Paths.PROCESSED / "osgsl" / "osgsl_subregional.parquet") # Sub-regional greenspace

# Load road network
nodes: cudf.DataFrame = cudf.from_pandas(
    pd.read_parquet(Paths.OS_GRAPH / "nodes.parquet") # Nodes
)
edges: cudf.DataFrame = cudf.from_pandas(
    pd.read_parquet(Paths.OS_GRAPH / "edges.parquet") # Edges
)

# Link the greenspace access points to the road network (1 = closest one, but can increase if want to match to more parts of the networks)
greenspace, nodes, edges = add_to_graph(greenspace, nodes, edges, 1)

# Load households (TOIDs)
toids = pd.read_parquet(Paths.PROCESSED / "toids_cm_osgb.parquet") # Load
# toids = toids.sample(100, random_state = 1234) # For testing purposes, subset a smaller dataset

# Link each household to the road network
toids, nodes, edges = add_to_graph(toids, nodes, edges, 2) # Here we have found that using n=2 is better as sometimes the closest road network piece is not always the best value

# Match green spaces to TOIDs
greenspace = add_topk(greenspace, toids, 3)

# Define the routing parameters
routing = Routing(
    name="greenspace",
    edges=edges,
    nodes=nodes,
    outputs=toids,
    inputs=greenspace,
    #weights="time_weighted", # Use to get time (mins)
    weights="length", # Use to get the distance (meters)
    min_buffer=5000,
    max_buffer=500_000,
    #cutoff=60, # Max value - so here 60 for time would be that if route is > 60 mins, then just set value as 60
)

# Process the data to estimate the routes between TOIDs and greenspaces
routing.fit()

# Get distances
routing.distances

# Store the distances
distances = (
    routing.distances.set_index("vertex")
    .join(cudf.from_pandas(toids).set_index("node_id"), how="right")
    .reset_index()
)

# Save the output
OUT_FILE = Paths.OUT_DATA / "distances_greenspace_topk3.csv"
distances[["TOID", "distance"]].to_csv(OUT_FILE, index=False)
