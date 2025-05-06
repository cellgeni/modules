include { TILEDIMAGESEGMENTATION_CELLPOSEWRAPPER as CELLPOSE } from '../../../modules/nf-core/tiledimagesegmentation/cellposewrapper'
include { TILEDIMAGESEGMENTATION_STARDISTWRAPPER as STARDIST} from '../../../modules/nf-core/tiledimagesegmentation/stardistwrapper'
include { TILEDIMAGESEGMENTATION_INSTANSEGWRAPPER as INSTANSEG} from '../../../modules/nf-core/tiledimagesegmentation/instansegwrapper'
include { TILEDIMAGESEGMENTATION_DEEPCELLWRAPPER as DEEPCELL} from '../../../modules/nf-core/tiledimagesegmentation/deepcellwrapper'
include { TILEDIMAGESEGMENTATION_MERGEOUTLINES as MERGEOUTLINES} from '../../../modules/nf-core/tiledimagesegmentation/mergeoutlines'
include { TILEDIMAGESEGMENTATION_GENERATETILECOORDS as GENERATE_TILE_COORDS } from '../../../modules/nf-core/tiledimagesegmentation/generatetilecoords'


workflow TILED_SEGMENTATION {
    take:
    images 
    method

    main:
    ch_versions = Channel.empty()
    GENERATE_TILE_COORDS(images)
    ch_versions = ch_versions.mix(GENERATE_TILE_COORDS.out.versions.first())

    images_tiles = GENERATE_TILE_COORDS.out.tile_coords.splitCsv(header:true, sep:",").map{ meta, coords ->
        [meta, coords.X_MIN, coords.Y_MIN, coords.X_MAX, coords.Y_MAX]
    }
    tiles_and_images = images_tiles.combine(images, by:0)
    if (method == "CELLPOSE") {
        CELLPOSE(tiles_and_images.combine(channel.from(params.cell_diameters)))
        wkts = CELLPOSE.out.wkts.groupTuple(by:0)
        ch_versions = ch_versions.mix(CELLPOSE.out.versions.first())
    } else if (method == "STARDIST") {
        STARDIST(tiles_and_images)
        wkts = STARDIST.out.wkts.groupTuple(by:0)
        ch_versions = ch_versions.mix(STARDIST.out.versions.first())
    } else if (method == "INSTANSEG") {
        INSTANSEG(tiles_and_images)
        wkts = INSTANSEG.out.wkts.groupTuple(by:0)
        ch_versions = ch_versions.mix(INSTANSEG.out.versions.first())
    } else if (method == "DEEPCELL") {
        DEEPCELL(tiles_and_images)
        wkts = DEEPCELL.out.wkts.groupTuple(by:0)
        ch_versions = ch_versions.mix(DEEPCELL.out.versions.first())
    } else {
        error "Invalid segmentation method: ${method}. Expected one of: CELLPOSE, STARDIST, INSTANSEG, DEEPCELL"
    }
    MERGEOUTLINES(wkts)
    ch_versions = ch_versions.mix(MERGEOUTLINES.out.versions.first())

    emit:
    geojson         = MERGEOUTLINES.out.multipoly_geojsons   // channel: [ val(meta), [ geojson ] ]
    versions    = ch_versions                     // channel: [ versions.yml ]
}