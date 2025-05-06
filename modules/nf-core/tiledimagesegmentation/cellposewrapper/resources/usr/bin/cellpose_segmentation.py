#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Copyright (c) 2024 Wellcome Sanger Institute

"""
This script will slice the image in XY dimension and save the slices coordinates in json files
"""
import argparse
import logging
import os

import numpy as np
import rasterio.features
import shapely.geometry
import shapely.wkt
import tifffile
import zarr
from cellpose import core, models


logging.basicConfig(level=logging.INFO)

VERSION="0.1.1"

def get_tile(image, xmin, xmax, ymin, ymax, channel=0, zplane=0, timepoint=0):
    dimension_order = [d[0] for d in image.attrs["_ARRAY_DIMENSIONS"]]
    dimension_order = "".join(dimension_order)
    if dimension_order=="YX":
        tile = image[ymin:ymax, xmin:xmax]
    elif dimension_order=="YXC" or dimension_order=="YXS":
        tile = image[ymin:ymax, xmin:xmax, channel]
    elif dimension_order=="CYX" or dimension_order=="SYX":
        tile = image[channel, ymin:ymax, xmin:xmax]
    elif dimension_order=="ZYX":
        tile = image[zplane, ymin:ymax, xmin:xmax]
    elif dimension_order=="ZYXC":
        tile = image[zplane, ymin:ymax, xmin:xmax, channel]
    elif dimension_order=="YXCZ":
        tile = image[ymin:ymax, xmin:xmax, channel, zplane]
    elif dimension_order=="XYCZT":
        tile = image[ymin:ymax, xmin:xmax, channel, zplane, timepoint]
    else:
        raise Exception(f"Unknown dimension order {dimension_order}")
    
    logging.debug(f"tile shape {tile.shape}")
    return tile
    

def cellpose_masks_to_shapely_polygons(masks, x_offset, y_offset):
    polygons = []
    for geom, value in rasterio.features.shapes(masks):
        if value == 0:  # ignore background (in cellpose mask 0)
            continue 
        poly = shapely.geometry.shape(geom)
        if poly.is_valid and not poly.is_empty:
            poly = shapely.affinity.translate(poly, xoff=x_offset, yoff=y_offset)
            polygons.append(poly)
    return polygons


def main(
    id:str,
    image_path:str,
    tile_id:str,
    x_min:int, x_max:int, 
    y_min:int, y_max:int,
    cell_diameter:int=30,
    segmentation_model:str="cyto3",
    zplane:int=0,
    channels:list=[0, 0],
    resolution_level:int=0,
    ):

    logging.info(f"loading cellpose model: {segmentation_model} | GPU? {core.use_gpu()}")
    # check if the model is the full path to the model or only the model_type
    if os.path.exists(segmentation_model):
        model = models.CellposeModel(gpu=core.use_gpu(), pretrained_model=segmentation_model)
    else:
        model = models.CellposeModel(gpu=core.use_gpu(), model_type=segmentation_model)

    logging.debug(f"reading image {image_path} at level {resolution_level}")
    store = tifffile.imread(image_path, aszarr=True)
    zgroup = zarr.open(store, mode="r")
    image = zgroup[resolution_level]
    logging.debug(f"image shape: {image.shape}")

    logging.info(f"reading id={id} x=[{x_min} : {x_max}] y=[{y_min} : {y_max}]")
    tile = get_tile(image, x_min, x_max, y_min, y_max, zplane=zplane)
    cellpose_results =  model.eval(tile, channels=channels, diameter=cell_diameter)

    if len(cellpose_results) == 3:
        logging.warning(f"cellpose result has only 3 elements")
        masks, flows, styles = cellpose_results
    else:
        masks, flows, styles, diams = cellpose_results
    
    os.makedirs(id, exist_ok=True)
    
    np.save(f"{id}/{tile_id}.npy", masks)
    
    # convert cellpose masks to WTK
    cells_detected = len(np.unique(masks[masks!=0]))
    logging.info(f"converting {cells_detected} cells in mask to WKT format")
    with open(f"{id}/{tile_id}.wkt", "wt") as f:
        if cells_detected:
            polygons = cellpose_masks_to_shapely_polygons(masks, x_offset=x_min, y_offset=y_min)
            polygons = shapely.geometry.MultiPolygon(polygons)
            f.write(polygons.wkt)
        else:
            f.write("")


if __name__ == "__main__":
    # define argument parser for command line arguments
    parser = argparse.ArgumentParser(description="cellpose segmentation")
    # argument declarations
    parser.add_argument("--id", type=str)
    parser.add_argument("--tile_id", type=str)
    parser.add_argument("--image_path", type=str)
    parser.add_argument("--x_min", default="0", type=int)
    parser.add_argument("--x_max", default="0", type=int)
    parser.add_argument("--y_min", default="0", type=int)
    parser.add_argument("--y_max", default="0", type=int)
    parser.add_argument("--cell_diameter", default=30, type=int)
    parser.add_argument("--segmentation_model", default="cyto3", type=str)
    parser.add_argument("--resolution_level", default=0, type=int)

    # parse command line arguments
    try:
        args = parser.parse_args()
    except Exception as ex:
        parser.print_help()
        SystemExit(ex)

    # invoke main function with parsed arguments
    main(**vars(args))
