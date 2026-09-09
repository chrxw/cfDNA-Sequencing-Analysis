###########################################
# CONFIG
###########################################
import os
import re
from collections import defaultdict

configfile: "config.yaml"

REF = config["configs"]["ref_genome"]
DIR_FASTQ = config["configs"]["directory_fastq"]
DIR_OUT   = config["configs"]["directory_output"]

###########################################
# BUILD SAMPLE STRUCTURE
###########################################

SAMPLES_DICT = defaultdict(list)

# ---- (1) Top-level FASTQ ----
for f in os.listdir(DIR_FASTQ):
    if f.endswith(".fastq.gz") and os.path.isfile(os.path.join(DIR_FASTQ, f)):
        m = re.match(r"(.+)_R([12])\.fastq\.gz$", f)
        if m:
            sample, r = m.groups()
            SAMPLES_DICT[sample].append(f.replace(".fastq.gz", ""))

# ---- (2) Subdirectories (multiple libraries) ----
for sub in os.listdir(DIR_FASTQ):
    sub_path = os.path.join(DIR_FASTQ, sub)
    if os.path.isdir(sub_path):
        libs = defaultdict(list)
        for f in os.listdir(sub_path):
            if f.endswith(".fastq.gz"):
                m = re.match(r"(.+)_R([12])\.fastq\.gz$", f)
                if m:
                    libname, r = m.groups()
                    libs[libname].append(f.replace(".fastq.gz", ""))

        for libname, libfiles in libs.items():
            sorted_libfiles = sorted(libfiles, key=lambda x: x[-2:])
            SAMPLES_DICT[sub].append(tuple(sorted_libfiles))

# ---- (3) Normalize R1/R2 (top-level) ----
for sample, files in SAMPLES_DICT.items():
    new_list = []
    for f in files:
        if isinstance(f, str):
            r1 = next(x for x in files if x.endswith("_R1"))
            r2 = next(x for x in files if x.endswith("_R2"))
            new_list.append((r1, r2))
            break
        else:
            new_list.append(f)
    SAMPLES_DICT[sample] = new_list

# ---- (4) Convert to SAMPLES_WITH_DIR ----
SAMPLES_WITH_DIR = {}
for sample, pairs in SAMPLES_DICT.items():
    pairs2 = []
    for r1, r2 in pairs:
        subdir = sample if os.path.isdir(os.path.join(DIR_FASTQ, sample)) else ""
        pairs2.append((subdir, r1, r2))
    SAMPLES_WITH_DIR[sample] = pairs2

import pprint
print("===== CHECK SAMPLES =====")
pprint.pprint(SAMPLES_WITH_DIR)
print("=========================")

###########################################
## MERGE HELPERS
############################################

def get_sample_bams(wc):
    return [
        os.path.join(DIR_OUT, wc.sample, "01_bwa", f"{r1}-{r2}.bam")
        for _, r1, r2 in SAMPLES_WITH_DIR[wc.sample]
    ]

def need_merge(wc):
     return len(SAMPLES_WITH_DIR[wc.sample]) > 1

###########################################
# FASTQC TARGETS (exact, no expand issues)
###########################################
FASTQC_OUTPUT = []
for sample, pairs in SAMPLES_WITH_DIR.items():
    for _, r1, r2 in pairs:
        FASTQC_OUTPUT += [
            os.path.join(DIR_OUT, sample, "00_fastqc", f"{r1}_fastqc.html"),
            os.path.join(DIR_OUT, sample, "00_fastqc", f"{r1}_fastqc.zip"),
            os.path.join(DIR_OUT, sample, "00_fastqc", f"{r2}_fastqc.html"),
            os.path.join(DIR_OUT, sample, "00_fastqc", f"{r2}_fastqc.zip"),
        ]


###########################################
# RULE ALL
###########################################

rule all:
    input:
        FASTQC_OUTPUT,
        # markdup index
        expand(f"{DIR_OUT}/{{sample}}/02_markdup_index/{{sample}}_MD.bam", sample=SAMPLES_DICT.keys()),
        # wig files
        expand(f"{DIR_OUT}/{{sample}}/03_readcounter/{{sample}}.wig", sample=SAMPLES_DICT.keys()),
        # ichorCNA files
        expand(
            f"{DIR_OUT}/{{sample}}/04_ichorCNA/{{sample}}.{{ext}}",
            sample=SAMPLES_DICT.keys(),
            ext=["correctedDepth.txt","params.txt","cna.seg","seg.txt","seg","RData"]
        )


###########################################
# RULE FASTQC
###########################################

rule fastqc:
    input:
        fq=lambda wc: (
            os.path.join(DIR_FASTQ, wc.sample, f"{wc.read}.fastq.gz")
            if os.path.isdir(os.path.join(DIR_FASTQ, wc.sample))
            else os.path.join(DIR_FASTQ, f"{wc.read}.fastq.gz")
        )
    output:
        html=os.path.join(DIR_OUT, "{sample}", "00_fastqc", "{read}_fastqc.html"),
        zip=os.path.join(DIR_OUT, "{sample}", "00_fastqc", "{read}_fastqc.zip")
    params:
        outdir=lambda wc: os.path.join(DIR_OUT, wc.sample, "00_fastqc")
    benchmark:
        "benchmarks/fastqc.{sample}.{read}.txt"
    shell:
        """
        #mkdir -p {params.outdir}
        fastqc {input.fq} --outdir {params.outdir}
        """


###########################################
# RULE BWA MEM
###########################################

rule bwa_mem:
    input:
        ref=REF,
        r1=lambda wc: (
            os.path.join(DIR_FASTQ, wc.sample, f"{wc.r1}.fastq.gz")
            if os.path.isdir(os.path.join(DIR_FASTQ, wc.sample))
            else os.path.join(DIR_FASTQ, f"{wc.r1}.fastq.gz")
        ),
        r2=lambda wc: (
            os.path.join(DIR_FASTQ, wc.sample, f"{wc.r2}.fastq.gz")
            if os.path.isdir(os.path.join(DIR_FASTQ, wc.sample))
            else os.path.join(DIR_FASTQ, f"{wc.r2}.fastq.gz")
        )
    output:
        bam=os.path.join(DIR_OUT, "{sample}", "01_bwa","{r1}-{r2}.bam")
    threads: 16
    params:
        outdir=lambda wc: os.path.join(DIR_OUT, wc.sample, "01_bwa")
    benchmark:
        "benchmarks/bwa_mem.{sample}.{r1}-{r2}.txt"
    shell:
        """
        #mkdir -p {params.outdir}
        bwa mem -t {threads} {input.ref} {input.r1} {input.r2} |
            samtools view -bSu - |
            samtools sort -o {output.bam}
        """


###########################################
## MERGE / NO MERGE BAMS
############################################

rule merge_bams:
    input:
        bams=get_sample_bams
    output:
        bam=os.path.join(DIR_OUT, "{sample}", "merge", "{sample}_merged.bam")
    params:                                                                        
        inputs=lambda wc, input: " ".join(f"I={b}" for b in input.bams)
    benchmark:      
       "benchmarks/merge_bams.{sample}.txt"
    shell:
       "picard MergeSamFiles {params.inputs} O={output.bam}"


###########################################
# MARK DUPLICATES
###########################################

rule mark_duplicates_index:
    input:
        bam=lambda wc: (
            os.path.join(DIR_OUT, wc.sample, "merge", f"{wc.sample}_merged.bam")
            if need_merge(wc)
            else get_sample_bams(wc)[0]
        )
    output:
        bam_md=os.path.join(DIR_OUT, "{sample}", "02_markdup_index", "{sample}_MD.bam"),
        metrics=os.path.join(DIR_OUT, "{sample}", "02_markdup_index", "{sample}_MD.txt"),
        bai=os.path.join(DIR_OUT, "{sample}", "02_markdup_index", "{sample}_MD.bam.bai")
    benchmark:
        "benchmarks/markdup.{sample}.txt"
    shell:
        """
        picard MarkDuplicates I={input.bam} O={output.bam_md} M={output.metrics}
        samtools index {output.bam_md} {output.bai}
        """


###########################################
# READCOUNTER → WIG
###########################################

rule read_counter:
    input:
        bam=lambda wc: os.path.join(DIR_OUT, wc.sample, "02_markdup_index", f"{wc.sample}_MD.bam")
    output:
        wig=os.path.join(DIR_OUT, "{sample}", "03_readcounter", "{sample}.wig")
    params:
        win=config["binSize"],
        quality="20",
        chrs=config["chrs"]
    benchmark:
        "benchmarks/readcounter.{sample}.txt"
    shell:
        """
        readCounter --window {params.win} --quality {params.quality} \
            --chromosome "{params.chrs}" {input.bam} > {output.wig}
        """


###########################################
# ICHORCNA
###########################################

rule ichorCNA:
    input:
        wig=lambda wc: os.path.join(DIR_OUT, wc.sample, "03_readcounter", f"{wc.sample}.wig")
    output:
        corrected=os.path.join(DIR_OUT, "{sample}", "04_ichorCNA", "{sample}.correctedDepth.txt"),
        params_out=os.path.join(DIR_OUT, "{sample}", "04_ichorCNA", "{sample}.params.txt"),
        cna=os.path.join(DIR_OUT, "{sample}", "04_ichorCNA", "{sample}.cna.seg"),
        segTxt=os.path.join(DIR_OUT, "{sample}", "04_ichorCNA", "{sample}.seg.txt"),
        seg=os.path.join(DIR_OUT, "{sample}", "04_ichorCNA", "{sample}.seg"),
        rdata=os.path.join(DIR_OUT, "{sample}", "04_ichorCNA", "{sample}.RData")
    params:
        rscript=config["ichorCNA"]["ichorCNA_rscript"],
        ploidy = config["ichorCNA"]["ichorCNA_ploidy"],
        normal = config["ichorCNA"]["ichorCNA_normal"],
        normalPanel = config["ichorCNA"]["ichorCNA_normalPanel"],
        maxCN = config["ichorCNA"]["ichorCNA_maxCN"],
        gcWig = config["ichorCNA"]["ichorCNA_gcWig"],
        mapWig = config["ichorCNA"]["ichorCNA_mapWig"],
        centromere = config["ichorCNA"]["ichorCNA_centromere"],
        includeHOMD = config["ichorCNA"]["ichorCNA_includeHOMD"],
        chrs = config["ichorCNA"]["ichorCNA_chrs"],
        chrTrain = config["ichorCNA"]["ichorCNA_chrTrain"],
        estimateNormal = config["ichorCNA"]["ichorCNA_estimateNormal"],
        estimatePloidy = config["ichorCNA"]["ichorCNA_estimatePloidy"],
        estimateScPrevalence = config["ichorCNA"]["ichorCNA_estimateScPrevalence"],
        scStates = config["ichorCNA"]["ichorCNA_scStates"],
        txnE = config["ichorCNA"]["ichorCNA_txnE"],
        txnStrength = config["ichorCNA"]["ichorCNA_txnStrength"],
        genomeStyle = config["ichorCNA"]["ichorCNA_genomeStyle"],
        minSegmentBin = config["ichorCNA"]["ichorCNA_minSegmentBin"],
        altFracThreshold = config["ichorCNA"]["ichorCNA_altFracThreshold"],
             
        outDir=lambda wc: os.path.join(DIR_OUT, wc.sample, "04_ichorCNA")
    benchmark:
        "benchmarks/ichorCNA.{sample}.txt"
    shell:
        """
        mkdir -p {params.outDir}
        Rscript {params.rscript} \
            --id {wildcards.sample} \
            --WIG {input.wig} \
            --ploidy "{params.ploidy}" \
            --normal "{params.normal}" \
            --maxCN {params.maxCN} \
            --gcWig {params.gcWig} \
            --mapWig {params.mapWig} \
            --centromere {params.centromere} \
            --normalPanel {params.normalPanel} \
            --includeHOMD {params.includeHOMD} \
            --chrs "{params.chrs}" \
            --chrTrain "{params.chrTrain}" \
            --estimateNormal {params.estimateNormal} \
            --estimatePloidy {params.estimatePloidy} \
            --estimateScPrevalence {params.estimateScPrevalence} \
            --scStates "{params.scStates}" \
            --txnE {params.txnE} \
            --txnStrength {params.txnStrength} \
            --genomeStyle {params.genomeStyle} \
            --minSegmentBin {params.minSegmentBin} \
            --altFracThreshold {params.altFracThreshold} \
            --outDir {params.outDir}
        """
