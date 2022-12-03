#!/usr/bin/env nextflow

nextflow.enable.dsl = 2

include { BIOINFOTONGLI_RAW2OMETIFF } from '../../../../modules/bioinfotongli/raw2ometiff/main.nf'

workflow test_bioinfotongli_raw2ometiff {
    
    input = [
        [ id:'test', single_end:false ], // meta map
        file(params.test_data['sarscov2']['illumina']['test_paired_end_bam'], checkIfExists: true)
    ]

    BIOINFOTONGLI_RAW2OMETIFF ( input )
}
