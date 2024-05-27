configfile: "/home/chrwan_ja/config/config_ich_web.yml"
configfile: "/home/chrwan_ja/config/sample_web.yml"

PATIENTS = config['samples_config']['PATIENTS']
PLASMAS = config['samples_config']['PLASMAS']
SAMPLES = config['samples_config']['SAMPLES']
PAIRED = config['samples_config']['PAIRED']
DIRECTORY = config['samples_config']['directory_output']
DIRECTORY_FASTQ = config['samples_config']['directory_fastq']
WORKFLOW_NAME = config['samples_config']['workflow_name']

rule all:
	input:
		expand("{directory}/{workflow_name}/ichorCNA/{patient}_{plasma}.{file_ext}", workflow_name=WORKFLOW_NAME, directory=DIRECTORY, patient=PATIENTS, plasma=PLASMAS, file_ext=["correctedDepth.txt", "params.txt", "cna.seg", "seg.txt", "seg", "RData"]),
		expand("{directory}/{workflow_name}/fastqc/{sample}_{pair}_fastqc.html", workflow_name=WORKFLOW_NAME, directory=DIRECTORY, sample=SAMPLES, pair=PAIRED),
		expand("{directory}/{workflow_name}/fastqc/{sample}_{pair}_fastqc.zip", workflow_name=WORKFLOW_NAME, directory=DIRECTORY, sample=SAMPLES, pair=PAIRED)

rule fastqc:
	input: 
		expand("{directory_fastq}/{workflow_name}/{sample}_{pair}.fastq.gz", workflow_name=WORKFLOW_NAME, directory_fastq=DIRECTORY_FASTQ, sample=SAMPLES, pair=PAIRED)
	output:
		html="{sample}_{pair}_fastqc.html",
		zip="{sample}_{pair}_fastqc.zip"
	conda:
		"/home/chrwan_ja/env/quality_control.yml"
	params:
		outdir=expand("{directory}/{workflow_name}/{patient}/{plasma}/fastqc", workflow_name=WORKFLOW_NAME, directory=DIRECTORY, sample=SAMPLES, patient=PATIENTS, plasma=PLASMAS),
		all=expand("{directory}/{workflow_name}/{patient}/{plasma}/fastqc.zip", workflow_name=WORKFLOW_NAME, directory=DIRECTORY, sample=SAMPLES, patient=PATIENTS, plasma=PLASMAS)
	shell: 
		"""
		fastqc {input} --outdir {params.outdir} && cd {params.outdir} && zip -r {params.all} *
		"""

num_bam_files = len(SAMPLES)

print(num_bam_files)

# Check the number of BAM files and perform operations accordingly
if num_bam_files == 1:
	rule bwamem_sort:
		input:
			"/home/chrwan_ja/ReferenceGenome/GCA_000001405.15_GRCh38_no_alt_plus_hs38d1_analysis_set.fna",
			expand("{directory_fastq}/{workflow_name}/{sample}_R1.fastq.gz", workflow_name=WORKFLOW_NAME, sample=SAMPLES , directory_fastq=DIRECTORY_FASTQ),
			expand("{directory_fastq}/{workflow_name}/{sample}_R2.fastq.gz", workflow_name=WORKFLOW_NAME, sample=SAMPLES , directory_fastq=DIRECTORY_FASTQ)
		output:
			expand("{directory}/{workflow_name}/{sample}.bam", workflow_name=WORKFLOW_NAME, directory=DIRECTORY, sample=SAMPLES)
		conda:
			"/home/chrwan_ja/env/mapping.yml"
		threads: 8
		shell:
			"""
			bwa mem -M -t {threads} {input[0]} {input[1]} {input[2]} | samtools view -bSu - | samtools sort -o {output}
			"""

	rule rename:
		input:
			expand("{directory}/{workflow_name}/{sample}.bam", workflow_name=WORKFLOW_NAME, directory=DIRECTORY, sample=SAMPLES)
		output:
			expand("{directory}/{workflow_name}/{patient}_{plasma}.bam", workflow_name=WORKFLOW_NAME, directory=DIRECTORY, plasma=PLASMAS, patient=PATIENTS)
		shell:
			"""
			mv {input} {output}
			"""
            
elif num_bam_files == 2:
    # Define the merge_bams rule at the top level of the Snakefile
	rule bwamem_sort_1:
		input:
			"/omics/odcf/reference_data/legacy/ngs_share/assemblies/hg_GRCh38/indexes/bwa/bwa06/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna",
			expand("{directory_fastq}/{workflow_name}/{sample}_R1.fastq.gz", sample=SAMPLES[0] ,workflow_name=WORKFLOW_NAME, directory_fastq=DIRECTORY_FASTQ),
			expand("{directory_fastq}/{workflow_name}/{sample}_R2.fastq.gz", sample=SAMPLES[0] ,workflow_name=WORKFLOW_NAME, directory_fastq=DIRECTORY_FASTQ)
		output:
			expand("{directory}/{workflow_name}/{sample}.bam", workflow_name=WORKFLOW_NAME, directory=DIRECTORY, sample=SAMPLES[0])
		conda:
			"/home/chrwan_ja/env/mapping.yml"
		threads: 8
		shell:
			"""
			bwa mem -M -t {threads} {input[0]} {input[1]} {input[2]} | samtools view -bSu - | samtools sort -o {output}
			"""
	rule bwamem_sort_2:
		input:
			"/omics/odcf/reference_data/legacy/ngs_share/assemblies/hg_GRCh38/indexes/bwa/bwa06/GCA_000001405.15_GRCh38_no_alt_analysis_set.fna.gz",
			expand("{directory_fastq}/{workflow_name}/{sample}_R1.fastq.gz", sample=SAMPLES[1] , workflow_name=WORKFLOW_NAME, directory_fastq=DIRECTORY_FASTQ),
			expand("{directory_fastq}/{workflow_name}/{sample}_R2.fastq.gz", sample=SAMPLES[1] , workflow_name=WORKFLOW_NAME, directory_fastq=DIRECTORY_FASTQ)
		output:
			expand("{directory}/{workflow_name}/{sample}.bam", workflow_name=WORKFLOW_NAME, directory=DIRECTORY, sample=SAMPLES[1])
		conda:
			"/home/chrwan_ja/env/mapping.yml"
		threads: 8
		shell:
			"""
			bwa mem -M -t {threads} {input[0]} {input[1]} {input[2]} | samtools view -bSu - | samtools sort -o {output}
			"""

	rule merge_bams:
		input:
			expand("{directory}/{workflow_name}/{sample}.bam", workflow_name=WORKFLOW_NAME, directory=DIRECTORY, sample=SAMPLES),
			expand("{directory}/{workflow_name}/{sample}.bam", workflow_name=WORKFLOW_NAME, directory=DIRECTORY, sample=SAMPLES)
		output:
			expand("{directory}/{workflow_name}/{patient}_{plasma}.bam", workflow_name=WORKFLOW_NAME, directory=DIRECTORY, plasma=PLASMAS, patient=PATIENTS)
		conda:
			"/home/chrwan_ja/env/mark_duplicate.yml"
		shell:
			"""
			picard MergeSamFiles I={input[0]} I={input[1]} O={output}
			"""


rule process_bam:
	input:
		bam="{directory}/{workflow_name}/{patient}_{plasma}.bam"
	output:
		bam_md="{directory}/{workflow_name}/{patient}_{plasma}_MD.bam",
		metrics="{directory}/{workflow_name}/{patient}_{plasma}_MD.txt",
		bam_index="{directory}/{workflow_name}/{patient}_{plasma}_MD.bam.bai"
	conda:
		"/home/chrwan_ja/env/mark_duplicate.yml"
	shell:
		"""
		picard MarkDuplicates I={input.bam} O={output.bam_md} M={output.metrics} && samtools index {output.bam_md} {output.bam_index}
		"""

rule read_counter:
	input:
		index=expand("{directory}/{workflow_name}/{patient}_{plasma}_MD.bam",workflow_name=WORKFLOW_NAME, directory=DIRECTORY, patient=PATIENTS, plasma=PLASMAS)
	output:
		wig=expand("{directory}/{workflow_name}/{patient}_{plasma}.wig", workflow_name=WORKFLOW_NAME, directory=DIRECTORY, patient=PATIENTS, plasma=PLASMAS)
	conda:
		"/home/chrwan_ja/env/cnv_calling.yml"	
	params:
		window_size=config["binSize"],
		quality="20",
		chromosome=config["chrs"]
	resources:
		mem=4
	shell:
		"""
		readCounter --window {params.window_size} --quality {params.quality} --chromosome "{params.chromosome}" {input.index} > {output.wig}
		"""

rule ichorCNA:
	input:
		tum =expand("{directory}/{workflow_name}/{patient}_{plasma}.wig", workflow_name=WORKFLOW_NAME, directory=DIRECTORY, patient=PATIENTS, plasma=PLASMAS)
	output:
		corrDepth=expand("{directory}/{workflow_name}/ichorCNA/{patient}_{plasma}.correctedDepth.txt", workflow_name=WORKFLOW_NAME, directory=DIRECTORY, patient=PATIENTS, plasma=PLASMAS),
		param=expand("{directory}/{workflow_name}/ichorCNA/{patient}_{plasma}.params.txt", workflow_name=WORKFLOW_NAME, directory=DIRECTORY, patient=PATIENTS, plasma=PLASMAS),
		cna=expand("{directory}/{workflow_name}/ichorCNA/{patient}_{plasma}.cna.seg", workflow_name=WORKFLOW_NAME, directory=DIRECTORY, patient=PATIENTS, plasma=PLASMAS),
		segTxt=expand("{directory}/{workflow_name}/ichorCNA/{patient}_{plasma}.seg.txt", workflow_name=WORKFLOW_NAME, directory=DIRECTORY, patient=PATIENTS, plasma=PLASMAS),
		seg=expand("{directory}/{workflow_name}/ichorCNA/{patient}_{plasma}.seg", workflow_name=WORKFLOW_NAME, directory=DIRECTORY, patient=PATIENTS, plasma=PLASMAS),
		rdata=expand("{directory}/{workflow_name}/ichorCNA/{patient}_{plasma}.RData", workflow_name=WORKFLOW_NAME, directory=DIRECTORY, patient=PATIENTS, plasma=PLASMAS),
		zip=expand("{directory}/{workflow_name}/ichorCNA.zip", workflow_name=WORKFLOW_NAME, directory=DIRECTORY, patient=PATIENTS, plasma=PLASMAS)
	conda:
		"/home/chrwan_ja/env/cnv_calling.yml"
	params:
		rscript=config["ichorCNA_rscript"],
		id=expand("{patient}_{plasma}",patient=PATIENTS, plasma=PLASMAS),
		ploidy=config["ichorCNA_ploidy"],
		normal=config["ichorCNA_normal"],
		maxCN=config["ichorCNA_maxCN"],
		gcwig=config["ichorCNA_gcWig"],
		mapwig=config["ichorCNA_mapWig"],
		centromere=config["ichorCNA_centromere"],
		normalPanel=config["ichorCNA_normalPanel"],
		includeHOMD=config["ichorCNA_includeHOMD"],
		chrs=config["ichorCNA_chrs"],
		chrTrain=config["ichorCNA_chrTrain"],
		estimateNormal=config["ichorCNA_estimateNormal"],
		estimatePloidy=config["ichorCNA_estimatePloidy"],
		estimateScPrevalence=config["ichorCNA_estimateScPrevalence"],
		scStates=config["ichorCNA_scStates"],
		txnE=config["ichorCNA_txnE"],
		txnStrength=config["ichorCNA_txnStrength"],
		genomeStyle=config["ichorCNA_genomeStyle"],
		minSegmentBin=config["ichorCNA_minSegmentBin"],
		altFracThreshold=config["ichorCNA_altFracThreshold"],
		outDir=expand("{directory}/{workflow_name}/ichorCNA", directory=DIRECTORY, workflow_name=WORKFLOW_NAME)
	resources:
		mem=4	
	shell:
		"""
		Rscript {params.rscript} --id {params.id} --WIG {input.tum} --ploidy "{params.ploidy}" --normal "{params.normal}" --maxCN {params.maxCN} --gcWig {params.gcwig} --mapWig {params.mapwig} --centromere {params.centromere} --normalPanel {params.normalPanel} --includeHOMD {params.includeHOMD} --chrs "{params.chrs}" --chrTrain "{params.chrTrain}" --estimateNormal {params.estimateNormal} --estimatePloidy {params.estimatePloidy} --estimateScPrevalence {params.estimateScPrevalence} --scStates "{params.scStates}" --txnE {params.txnE} --txnStrength {params.txnStrength} --genomeStyle {params.genomeStyle} --minSegmentBin {params.minSegmentBin} --altFracThreshold {params.altFracThreshold} --outDir {params.outDir} && cd {params.outDir} && zip -r {output.zip} *
		"""