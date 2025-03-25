process IMAGESEGMENTATIONMETRICS {
    label 'process_single'
    nextflow.enable.moduleBinaries = true
    conda "${moduleDir}/environment.yml"
    container 'community.wave.seqera.io/library/fire_monai_rasterio_tifffile_pruned:106d8ac1dc78149c'

    input:
    tuple val(meta), path(ref_img), path(images2compare), val(metricname)

    output:
    tuple val(meta), path("*.csv"), emit: segmentation_metrics
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    segmentation_metrics.py run --path_ref ${ref_img} --path_list_seg "${images2compare}" --list_metrics "${metricname}" ${args}

    cat <<-END_VERSIONS > versions.yml
    ${task.process}:
        python: \$(python3 -c 'import platform; print(platform.python_version())')
        monai: \$(python3 -c 'import monai; print(monai.__version__)')
        seg-metrics: \$(segmentation_metrics.py version)

    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''

    // TODO nf-core: A stub section should mimic the execution of the original module as best as possible
    //               Have a look at the following examples:
    //               Simple example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bcftools/annotate/main.nf#L47-L63
    //               Complex example: https://github.com/nf-core/modules/blob/818474a292b4860ae8ff88e149fbcda68814114d/modules/nf-core/bedtools/split/main.nf#L38-L54
    """
    touch ${prefix}.csv

    cat <<-END_VERSIONS > versions.yml
    ${task.process}:
        python: \$(python3 -c 'import platform; print(platform.python_version())')
        monai: \$(python3 -c 'import monai; print(monai.__version__)')
        seg-metrics: \$(segmentation_metrics.py version)

    END_VERSIONS
    """
}
