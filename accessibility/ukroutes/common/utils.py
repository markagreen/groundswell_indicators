from pathlib import Path


class Paths:
    DATA = Path("data")
    RAW = DATA / "raw"
    OUT_DATA = DATA / "out"
    OPROAD = RAW / "oproad" / "oproad_gb.gpkg"
    FERRY = RAW / "oproad" / "strtgi_essh_gb" / "ferry_line.shp"

    PROCESSED = DATA / "processed"
    OS_GRAPH = PROCESSED / "oproads"


