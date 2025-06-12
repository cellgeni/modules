process TILEDIMAGESEGMENTATION_GENERATETILECOORDS {
    tag "${meta.id}"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "quay.io/cellgeni/imagetileprocessor:0.1.11"

    input:
    tuple val(meta), path(image)

    output:
    tuple val(meta), path("${output_name}"), emit: tile_coords
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    output_name = "${prefix}_tile_coords.csv"
    """
    tile-2d-image run \\
        --image ${image} \\
        --output_name "${output_name}" \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tile-2d-image: \$(tile-2d-image version)
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    output_name = "${prefix}_tile_coords.csv"
    """
    touch "${output_name}"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        tile-2d-image: \$(tile-2d-image version)
    END_VERSIONS
    """
}
