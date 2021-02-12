rule align_reads:
    """Align reads to reference with BWA.
    This step combines R1 and R2 data into a single output bam per
    fastq pair.  For samples where multiple fastq files represent a
    single sample, e.g. if a sample was run over several lanes, each
    R1/R1 fastq pair will be aligned separately here.  Then the aligned
    bams from a single sample will be combined during the dedup step
    below.  This should help modestly speed up alignment, as it's run
    in parallel for each fastq pair.
    """
    input:
        r="resources/Homo_sapiens_assembly38.fasta",
        r1="results/paired_trimmed_reads/{rg}_r1.fastq.gz",
        r2="results/paired_trimmed_reads/{rg}_r2.fastq.gz",
        d="resources/Homo_sapiens_assembly38.dict",
        fai="resources/Homo_sapiens_assembly38.fasta.fai",
        amb="resources/Homo_sapiens_assembly38.fasta.64.amb",
        ann="resources/Homo_sapiens_assembly38.fasta.64.ann",
        bwt="resources/Homo_sapiens_assembly38.fasta.64.bwt",
        pac="resources/Homo_sapiens_assembly38.fasta.64.pac",
        sa="resources/Homo_sapiens_assembly38.fasta.64.sa",
    output:
        temp("results/mapped/{rg}.bam"),
    benchmark:
        "results/performance_benchmarks/align_reads/{rg}.tsv"
    params:
        pl="ILLUMINA",
        sort_order="coordinate",
        rg="{rg}",
        sm=get_sm,
    threads: 24
    conda:
        "../envs/bwa_samtools.yaml"
    resources:
        mem_mb=10000
    shell:
        "bwa mem "
        "-K 10000000 -M "
        '-R "@RG\\tCN:54gene\\tID:{params.rg}\\tSM:{params.sm}\\tPL:{params.pl}\\tLB:N/A" '
        "-t {threads} "
        "{input.r} {input.r1} {input.r2} | "
        "samtools sort -@ 8 -m 3600M -o {output} - " # note - wanted to use bwa-mem2, but doesn't seem to be working via conda


rule mark_duplicates:
    """Mark duplicates and merge multiple bams per sample.

    If there are multiple fastq pairs per sample (e.g. if the sample
    is split over multiple lanes), I am waiting to merge them until
    this step, instead of concatenating them prior to alignment.  This
    is to help maintain some additional parallelization going in to
    alignment.
    """
    input:
        get_inputs_with_matching_SM,
    output:
        bam=temp("results/dedup/{sample}.bam"),
        metrics="results/dedup/{sample}.metrics.txt",
    benchmark:
        "results/performance_benchmarks/mark_duplicates/{sample}.tsv"
    params:
        l=list_markdup_inputs,
        t=tempDir,
    conda:
        "../envs/gatk.yaml"
    resources:
        mem_mb=10000,
    shell:
        'gatk --java-options "-Xmx2g -XX:+UseParallelGC -XX:ParallelGCThreads=2" MarkDuplicates '
        "TMP_DIR={params.t} "
        "REMOVE_DUPLICATES=true "
        "INPUT={params.l} "
        "OUTPUT={output.bam} "
        "METRICS_FILE={output.metrics}"


rule recalibrate_bams:
    """Calculate table for BQSR."""
    input:
        bam="results/dedup/{sample}.bam",
        r="resources/Homo_sapiens_assembly38.fasta",
        d="resources/Homo_sapiens_assembly38.dict",
        snps="resources/Homo_sapiens_assembly38.dbsnp138.vcf",
        s_index="resources/Homo_sapiens_assembly38.dbsnp138.vcf.idx",
        indels="resources/Homo_sapiens_assembly38.known_indels.vcf.gz",
        i_index="resources/Homo_sapiens_assembly38.known_indels.vcf.gz.tbi",
    output:
        table="results/bqsr/{sample}.recal_table",
    params:
        t=tempDir,
    benchmark:
        "results/performance_benchmarks/recalibrate_bams/{sample}.tsv"
    conda:
        "../envs/gatk.yaml"
    resources:
        mem_mb=8000,
    shell:
        'gatk --java-options "-Xmx4g -XX:+UseParallelGC -XX:ParallelGCThreads=20" BaseRecalibrator '
        "--tmp-dir {params.t} "
        "-R {input.r} "
        "-I {input.bam} "
        "--known-sites {input.snps} "
        "--known-sites {input.indels} "
        "-O {output.table}"


rule apply_bqsr:
    """Recalibrate bams."""
    input:
        bam="results/dedup/{sample}.bam",
        r="resources/Homo_sapiens_assembly38.fasta",
        d="resources/Homo_sapiens_assembly38.dict",
        recal="results/bqsr/{sample}.recal_table",
    output:
        bam="results/bqsr/{sample}.bam",
    params:
        t=tempDir,
    benchmark:
        "results/performance_benchmarks/apply_bqsr/{sample}.tsv"
    conda:
        "../envs/gatk.yaml"
    resources:
        mem_mb=20000,
    shell:
        'gatk --java-options "-Xmx10g" ApplyBQSR '
        "--tmp-dir {params.t} "
        "-R {input.r} "
        "-I {input.bam} "
        "--bqsr-recal-file {input.recal} "
        "-O {output.bam}"


rule index_bams:
    """Index post-BQSR bams."""
    input:
        "results/bqsr/{sample}.bam",
    output:
        "results/bqsr/{sample}.bam.bai",
    benchmark:
        "results/performance_benchmarks/index_bams/{sample}.tsv"
    conda:
        "../envs/bwa_samtools.yaml"
    shell:
        "samtools index {input} {output}"


rule samtools_stats:
    """Generate stats for bams.
    May want to do this pre-bqsr too.
    """
    input:
        bam="results/bqsr/{sample}.bam",
        bai="results/bqsr/{sample}.bam.bai",
    output:
        "results/alignment_stats/{sample}.txt",
    benchmark:
        "results/performance_benchmarks/samtools_stats/{sample}.tsv"
    conda:
        "../envs/bwa_samtools.yaml"
    shell:
        "samtools stats {input.bam} > {output}"
