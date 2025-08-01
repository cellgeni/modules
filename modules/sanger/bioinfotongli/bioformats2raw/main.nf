process BIOINFOTONGLI_BIOFORMATS2RAW {
    tag "${meta.id}"
    label 'process_medium'

    conda params.enable_conda ? "-c ome bioformats2raw==0.9.1" : null
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? "bioinfotongli/bioformats2raw:0.9.1"
        : "bioinfotongli/bioformats2raw:0.9.1"}"
    publishDir params.out_dir

    input:
    tuple val(meta), path(img)

    output:
    tuple val(meta), path("${stem}.zarr"), emit: zarr
    path "bioformats2raw_versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    if (meta['id'] == null) {
        meta['id'] = img.baseName
    }
    stem = meta['id']
    def args = task.ext.args ?: ''
    """
    /opt/conda/bin/bioformats2raw \\
        --max_workers=${task.cpus} \\
        ${args} \\
        ${img} \\
        "${stem}.zarr"

    cat <<-END_VERSIONS > bioformats2raw_versions.yml
    "${task.process}":
        bioinfotongli: \$(echo \$(JAVA_HOME='/opt/conda/lib/jvm' /opt/conda/bin/bioformats2raw --version 2>&1) | sed 's/^.*bioformats2raw //; s/Using.*\$//' ))
    END_VERSIONS
    """
}
