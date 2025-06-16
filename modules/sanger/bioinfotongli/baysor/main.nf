process BIOINFOTONGLI_BAYSOR {
    tag '$spots'
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? "vpetukhov/baysor:v0.6.2"
        : "vpetukhov/baysor:v0.6.2"}"
    containerOptions "${workflow.containerEngine == 'singularity' ? '--nv' : '--gpus all --user root -d'}"

    input:
    path spots

    output:
    path "segmentation.csv", emit: segmentation
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    baysor run \\
        ${spots} \\
        ${args} \\

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: vpetukhov/baysor:v0.6.2
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    """
    touch segmentation.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: baysor vpetukhov/baysor:v0.6.2
    END_VERSIONS
    """
}
