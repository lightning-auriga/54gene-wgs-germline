rule bcftools_extract_final_subject_list:
    """
    Use bcftools to extract subject set in final
    vcf file
    """
    input:
        vcf="results/post_qc_exclusions/samples_excluded.HC_variants.hardfiltered.vcf.gz",
    output:
        "results/run_summary/final_subject_list.tsv",
    conda:
        "../envs/bcftools.yaml"
    benchmark:
        "results/performance_benchmarks/bcftools_extract_final_subject_list/bcftools_extract_final_subject_list.tsv"
    shell:
        "bcftools query -l {input} > {output}"


rule run_summary:
    """
    Create a run summary report aggregating information
    about overall run that is poorly captured by multiqc.
    """
    input:
        output_subject_list="results/run_summary/final_subject_list.tsv",
        r_resources="workflow/scripts/run_summary_resources.R",
    output:
        "results/run_summary/run_summary.html",
    params:
        input_samples=SAMPLES,
    conda:
        "../envs/r.yaml"
    benchmark:
        "results/performance_benchmarks/run_summary/run_summary.tsv"
    script:
        "../scripts/run_summary.Rmd"
