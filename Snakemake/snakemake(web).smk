WORKFLOW_NAME = config["workflow_name"]
PAIRED = config["PAIRED"]
input_dir = "/home/chrwan_ja/input/{WORKFLOW_NAME}"
output_dir = "/home/chrwan_ja/output/{WORKFLOW_NAME}"

# Rule to define the pipeline order
rule all:
    input:
		expand("{directory}/ichorCNA/{sample}.{file_ext}", directory=output_dir, patient=PATIENTS, plasma=PLASMAS, file_ext=["correctedDepth.txt", "params.txt", "cna.seg", "seg.txt", "seg", "RData"]),
		expand("{directory}/fastqc/{sample}_{pair}_fastqc.html", directory=output_dir, sample=WORKFLOW_NAME, pair=PAIRED),
		expand("{directory}/fastqc/{sample}_{pair}_fastqc.zip", directory=output_dir, sample=WORKFLOW_NAME, pair=PAIRED)

# Rule to perform FastQC
rule fastqc:
    input:
		expand("{directory_fastq}/{sample}_{pair}.fastq.gz", directory_fastq=input_dir, sample=SAMPLES, pair=PAIRED)
    output:
        r1_out = "{output_dir}/R1_fastqc.html",
        r2_out = "{output_dir}/R2_fastqc.html"
    shell:
        """
        conda activate quality_control
        fastqc -o {output_dir} {input.r1}
        fastqc -o {output_dir} {input.r2}
        conda deactivate
        """

# Rule to perform Mapping, View, and Sort
rule mapping:
    input:
        r1 = "{input_dir}/R1/*.fastq.gz",
        r2 = "{input_dir}/R2/*.fastq.gz"
    output:
        bam = "{output_dir}/{sample_name}.bam"
    shell:
        """
        conda activate mapping
        bwa mem -M -t 4 /home/chrwan_ja/ReferenceGenome/GCA_000001405.15_GRCh38_no_alt_plus_hs38d1_analysis_set.fna {input.r1} {input.r2} | \
        samtools view -bSu - | samtools sort -o {output.bam}
        conda deactivate
        """

# Rule to perform Mark Duplication
rule mark_duplicates:
    input:
        bam = "{output_dir}/{sample_name}.bam"
    output:
        marked_bam = "{output_dir}/{sample_name}_MarkDup.bam",
        metrics = "{output_dir}/{sample_name}_MarkDup_metrics.txt"
    shell:
        """
        conda activate mark_duplicate
        picard MarkDuplicates I={input.bam} O={output.marked_bam} M={output.metrics}
        conda deactivate
        """

# Rule to perform Indexing
rule indexing:
    input:
        bam = "{output_dir}/{sample_name}_MarkDup.bam"
    output:
        bam_index = "{output.bam}.bai"
    shell:
        """
        conda activate indexing
        samtools index {input.bam}
        conda deactivate
        """

# Rule to perform Copy Number Variant Calling
rule cnv_calling:
    input:
        bam = "{output_dir}/{sample_name}_MarkDup.bam"
    output:
        wig = "{output_dir}/{sample_name}.wig",
        ichorCNA_dir = directory("{output_dir}/ichorCNA")
    shell:
        """
        conda activate cnv_calling
        readCounter --window 1000000 --quality 20 --chromosome "chr1,chr2,chr3,chr4,chr5,chr6,chr7,chr8,chr9,chr10,chr11,chr12,chr13,chr14,chr15,chr16,chr17,chr18,chr19,chr20,chr21,chr22,chrX,chrY" {input.bam} > {output.wig}
        mkdir -p {output.ichorCNA_dir} && Rscript /home/chrwan_ja/ichorCNA/scripts/runIchorCNA.R --id {sample_name} \
        --WIG {output.wig} --ploidy "c(2,3)" --normal "c(0.5,0.6,0.7,0.8,0.9,0.95)" --maxCN 5 \
        --gcWig /home/chrwan_ja/ichorCNA/inst/extdata/gc_hg38_1000kb.wig \
        --mapWig /home/chrwan_ja/ichorCNA/inst/extdata/map_hg38_1000kb.wig \
        --centromere /home/chrwan_ja/ichorCNA/inst/extdata/GRCh38.GCA_000001405.2_centromere_acen.txt --genomeStyle "UCSC" \
        --normalPanel /home/chrwan_ja/ichorCNA/inst/extdata/HD_ULP_PoN_hg38_1Mb_median_normAutosome_median.rds \
        --includeHOMD False --chrs "paste0('chr', c(1:22, \"X\"))" --chrTrain "paste0('chr', c(1:22))" \
        --estimateNormal True --estimatePloidy True --estimateScPrevalence True \
        --scStates "c(1,3)" --txnE 0.9999 --txnStrength 10000 --outDir {output.ichorCNA_dir}
        conda deactivate
        """
