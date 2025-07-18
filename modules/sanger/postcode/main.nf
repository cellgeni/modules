process POSTCODE {
    tag "${meta.id}"

    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? "quay.io/bioinfotongli/postcode:0.2.0"
        : "quay.io/bioinfotongli/postcode:0.2.0"}"

    input:
    tuple val(meta), file(spot_profile), file(spot_loc), file(codebook), file(readouts), val(R)

    output:
    tuple val(meta), path("${out_name}"), emit: decoded_peaks
    tuple val(meta), path("${prefix}_decode_out_parameters.pickle"), optional: true
    path "versions.yml", emit: versions

    script:
    prefix = meta.id ?: "none"
    out_name = "${prefix}_decoded_spots.csv"
    def args = task.ext.args ?: ""
    readouts = readouts ? "---readouts_csv ${readouts}" : ""
    n_round = task.ext.n_round ? "--R ${R}" : ""
    """
    decode.py run --spot_profile_p ${spot_profile} \
        --spot_locations_p ${spot_loc} \
        --codebook_p ${codebook} \
        --out_name ${out_name} \
        ${readouts} \
        ${n_round} \
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: \$(decode.py version)
    END_VERSIONS
    """

    stub:
    prefix = task.ext.prefix ?: "${meta.id}"
    out_name = "${prefix}_decoded_spots.csv"
    """
    touch ${out_name}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bioinfotongli: \$(decode.py version)
    END_VERSIONS
    """
}
