#!/usr/bin/env python
# -*- coding: utf-8 -*-
# Copyright (c) 2024 Wellcome Sanger Institute

"""
This script will slice the image in XY dimension and save the slices coordinates in json files
"""
import fire
from aicsimageio import AICSImage
from scipy import ndimage
from instanseg import InstanSeg
import cv2
import numpy as np
from shapely.geometry import Polygon, MultiPolygon
from shapely import to_wkt

import logging

logger = logging.getLogger(__name__)


def get_shapely(label):
    """
    get outlines of masks as a list to loop over for plotting
    """
    polygons = {}
    simpler_polys = {}
    slices = ndimage.find_objects(label)
    for i, bbox in enumerate(slices):
        if not bbox:
            continue
        cur_cell_label = i + 1
        msk = (label[bbox[0], bbox[1]] == cur_cell_label).astype(np.uint8).copy()
        cnts, _ = cv2.findContours(
            msk, cv2.RETR_TREE, cv2.CHAIN_APPROX_SIMPLE
        )
        # if len(cnts) > 1:
            # print(len(cnts), cur_cell_label)
        current_polygons = [
            Polygon((cnt + [bbox[1].start, bbox[0].start]).squeeze())
            #             else Point((cnt + [bbox[1].start, bbox[0].start]).squeeze())
            for cnt in cnts
            if len(cnt) > 2
        ]
        multipoly_obj = MultiPolygon(current_polygons)
        polygons[cur_cell_label] = multipoly_obj
        simpler_polys[cur_cell_label] = multipoly_obj.simplify(
            2, preserve_topology=True
        )
    return polygons, simpler_polys


def main(
        image_path: str,
        x_min: int, x_max: int, y_min: int, y_max: int,
        output: str,
        model: str = "fluorescence_nuclei_and_cells",
        channel_index: int = 0,
        T: int = 0,
    ):
    instanseg_fluorescence = InstanSeg(model, verbosity=1)
    img = AICSImage(image_path)

    if T>0:
        logger.warning("T is not supported yet, only the first frame will be processed")

    crop = img.get_image_dask_data("YX", S=0, T=0, C=channel_index)[y_min:y_max, x_min:x_max]

    labeled_output = instanseg_fluorescence.eval_small_image(
        np.array(crop).astype(np.uint16), None, return_image_tensor=False, target="nuclei",
        resolve_cell_and_nucleus=False, cleanup_fragments = True
    )
    polys = get_shapely(np.squeeze(np.array(labeled_output)).astype(np.uint16))

    with open(output, "wt") as f:
        f.write(to_wkt(MultiPolygon(polys[1].values())))
    

if __name__ == "__main__":
    options = {
        "run": main,
        "version": "0.0.1",
    }
    fire.Fire(options)
