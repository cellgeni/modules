process TILEDIMAGESEGMENTATION_MERGEOUTLINES {
    tag "$meta.id"

    container 'quay.io/cellgeni/imagetileprocessor:0.1.11'

    input:
    tuple val(meta), path(outlines)

    output:
    tuple val(meta), path("${prefix}.geojson"), emit: multipoly_geojsons
    tuple val(meta), path("${prefix}.wkt"), emit: multipoly_wkts, optional: true
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}_merged"
    """
    merge-polygons \\
        --wkts $outlines \\
        --output_prefix "${prefix}" \\
        $args \\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mergeoutlines: \$(merge-polygons --version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}_merged"
    """
    touch ${prefix}.geojson

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        mergeoutlines: \$(merge-polygons --version)
    END_VERSIONS
    """
}
