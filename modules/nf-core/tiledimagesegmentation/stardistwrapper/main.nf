process TILEDIMAGESEGMENTATION_STARDISTWRAPPER {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "quay.io/cellgeni/tiled_stardist:0.9.1-0.1.0"

    input:
    tuple val(meta), val(x_min), val(y_min), val(x_max), val(y_max), path(image)

    output:
    tuple val(meta), path("${out_name}"), emit: wkts
    tuple val(meta), path("${stem}*png"), emit: cp_plots, optional: true
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    stem = "${meta.id}-${x_min}_${y_min}_${x_max}_${y_max}"
    def args = task.ext.args ?: ''  
    out_name = "${stem}_cp_outlines.wkt"
    """
    export NUMBA_CACHE_DIR=/tmp/numba_cache
    stardist_helper.py run \
        --image_path ${image} \
        --x_min ${x_min} \
        --y_min ${y_min} \
        --x_max ${x_max} \
        --y_max ${y_max} \
        --output_name ${out_name} \
        ${args}
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tiledimagesegmentation/stardist: \$(stardist_helper.py version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    stem = "${meta.id}-${x_min}_${y_min}_${x_max}_${y_max}"
    out_name = "${stem}_cp_outlines.wkt"
    """
    touch ${out_name}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tiledimagesegmentation/stardist: \$(stardist_helper.py version)
    END_VERSIONS
    """
}
