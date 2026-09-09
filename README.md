# Automated Snakemake Workflow for cfDNA Fragmentomics and Machine Learning-Based Pediatric Cancer Classification

An automated and reproducible Snakemake-based workflow for low-coverage whole-genome sequencing (lcWGS) analysis of circulating cell-free DNA (cfDNA), integrating quality control, read alignment, BAM processing, copy-number analysis, fragmentomic feature extraction, and machine learning-based pediatric cancer classification.

## Table of Contents

- [Introduction](#introduction)
- [Workflow Overview](#workflow-overview)
- [Study Cohort](#study-cohort)
- [Prerequisites](#prerequisites)
- [Technologies](#technologies)
- [Running the Ensemble Analysis](#running-the-ensemble-analysis)
- [Key Findings](#key-findings)
- [Limitations](#limitations)
- [Privacy and Data Security](#privacy-and-data-security)
- [Acknowledgement](#acknowledgement)
- [License](#license)

---

## Introduction

Pediatric cancers, particularly brain tumors and sarcomas, present substantial diagnostic challenges because conventional tissue biopsy can be invasive and may be difficult or unsafe for tumors located in anatomically sensitive regions.

Cell-free DNA (cfDNA) obtained from plasma provides a minimally invasive substrate for cancer analysis. In addition to genomic alterations, cfDNA contains characteristic fragmentation patterns that can be quantified using whole-genome sequencing. These fragmentomic features include fragment length distributions, short-to-long fragment ratios, strand orientation, end-motif profiles, and tumor-associated measures.

This project provides an automated workflow for processing cfDNA sequencing data and integrating bioinformatics preprocessing, fragmentomic feature extraction, and machine learning classification within a single Snakemake workflow.

The workflow was developed to support scalable and reproducible cfDNA analysis in pediatric oncology and was evaluated for:

1. Cancer detection
2. Brain tumor detection
3. Sarcoma detection
4. Multiclass classification of healthy controls, brain tumors, and sarcomas

The workflow is designed to improve processing efficiency, reproducibility, and scalability for large-scale cfDNA sequencing analysis.

## Workflow Overview

The workflow consists of five major processing stages:

```text
Raw FASTQ files
        |
        v
Quality Control
(FastQC)
        |
        v
Read Alignment
(BWA-MEM)
        |
        v
BAM Processing
(SAMtools / Picard)
        |
        +----------------------+
        |                      |
        v                      v
CNA / Tumor Fraction      Fragmentomic Features
(ichorCNA)                (cfdnakit + custom scripts)
        |                      |
        +----------+-----------+
                   |
                   v
        Feature Engineering
        and Feature Selection
                   |
                   v
          Machine Learning
                   |
        +----------+----------+
        |          |          |
       KNN        SVM        RF
                              |
                            XGBoost
        |          |          |
        +----------+----------+
                   |
                   v
            Hard Voting
             Ensemble
                   |
                   v
      Cancer Detection and
       Subtype Classification
```

## Study Cohort

The analytical cohort consisted of:

- **349 plasma cfDNA samples**
- **96 pediatric cancer patients**
  - Brain tumors: 52 patients / 53 samples
  - Sarcomas: 44 patients / 58 samples
- **214 healthy controls**
  - INFORM registry: 10 samples
  - EGA datasets: 204 samples

Cancer-derived samples were obtained from the INFORM registry.

Healthy control samples were supplemented using publicly available datasets from the European Genome-phenome Archive (EGA).

---

## Prerequisites

Before running the workflow, ensure that the following software and computational resources are available.

### Operating System

- Ubuntu or another Linux-based operating system
- Access to a command-line environment

### Workflow and Programming

- Conda
- Python
- R
- Snakemake

### Bioinformatics Tools

The following tools are required for the cfDNA sequencing analysis workflow:

- FastQC
- BWA-MEM
- SAMtools
- Picard
- ichorCNA
- cfdnakit

### Machine Learning and R Packages

The machine learning and statistical analysis components require R and relevant R packages, including:

- caret
- randomForest
- kernlab
- class
- xgboost
- pROC
- ggplot2
- Biostrings
- cfdnakit

### High-Performance Computing

For large-scale or cohort-level analysis, an HPC environment is recommended with:

- Slurm workload manager
- Multi-core CPU resources
- Sufficient RAM
- Sufficient storage for sequencing data and intermediate files

---

## Technologies

### Bioinformatics

- **Snakemake** - Workflow management and automation
- **FastQC** - Quality control of sequencing reads
- **BWA-MEM** - Short-read alignment to the human reference genome
- **SAMtools** - SAM/BAM processing, sorting, and indexing
- **Picard** - BAM processing, read merging, and duplicate marking
- **ichorCNA** - Copy-number analysis and tumor fraction estimation
- **cfdnakit** - cfDNA fragmentomic feature extraction

### Machine Learning

- **R** - Statistical analysis and machine learning
- **caret** - Model training, preprocessing, and cross-validation
- **Random Forest** - Tree-based supervised classification
- **Support Vector Machine (SVM)** - Supervised classification
- **K-Nearest Neighbors (KNN)** - Instance-based classification
- **XGBoost** - Gradient boosting classification
- **pROC** - ROC curve and AUC analysis
- **ggplot2** - Data visualization

### Workflow and Computing Infrastructure

- **Snakemake** - Reproducible workflow management
- **Slurm** - HPC workload management and job scheduling
- **Conda** - Environment and dependency management
- **Linux / Ubuntu** - Computational environment

### Development and Deployment

- **GitHub** - Version control and source-code management
- **MobaXterm** - Remote server access and file management

---

## Running the Ensemble Analysis

The multiclass ensemble classification step is implemented in R and located in `Rscript-ENSEMBLE/`. It builds on the four pre-trained single models stored in `model/multi/` (KNN, SVM, XGBoost, and Random Forest) and classifies samples into three classes: healthy controls, brain tumors, and sarcomas. The four models are ranked by macro-averaged AUC on the test set, the top three are selected, and two ensembles are constructed from them: **Hard Voting** (majority vote, with ties resolved by the highest-AUC model) and **Soft Voting** (averaged class probabilities).

### Input Data

Patient-derived data are **not included in this repository**. Before running the analysis, make the required files available and point the scripts to them using environment variables:

```r
# train / validation / test splits: ML_multi_{train,val,test,encodeddf}.rds
Sys.setenv(CFDNA_DATA_DIR = "/path/to/dataframes")

# single-model reference results: ML_predictions_multi.xlsx,
# ML_ConfusionMetrics_multi.xlsx, {knn,svm,xgb,rf}_tuned_metrics_multi_seed.rds
Sys.setenv(CFDNA_REF_DIR = "/path/to/single_model_results")
```

Alternatively, place the files in `Rscript-ENSEMBLE/data/` and `Rscript-ENSEMBLE/data/reference/`, which are excluded from version control. If any required file is missing, the scripts stop and report exactly which files were not found.

### R Packages

```r
install.packages(c(
  "tidyverse", "caret", "pROC", "openxlsx",
  "ggplot2", "gridExtra", "scales",
  "randomForest", "xgboost", "e1071", "ranger", "kernlab"
))
```

`extrafont` is optional and is used by `05_pub_figures.R` to embed Times New Roman; a serif fallback is applied when it is unavailable.

### Execution

Run the complete pipeline from the repository root:

```bash
Rscript Rscript-ENSEMBLE/run_all.R
```

The scripts can also be run individually, in the following order:

| Script | Description |
|---|---|
| `01_single_model_analysis.R` | Evaluates the four single models on the train, validation, and test splits; computes accuracy, kappa, macro-AUC, macro-F1, and per-class metrics |
| `02_ensemble_multi.R` | Selects the top three models and builds the Hard Voting and Soft Voting ensembles |
| `03_combined_report.R` | Combines all results into a single multi-sheet Excel report |
| `04_quick_comparison.R` | Produces a condensed five-sheet comparison report |
| `05_pub_figures.R` | Generates publication-quality figures at web and print resolutions |

Scripts `02` to `05` depend on outputs written by earlier steps, so the order must be preserved. All output is written to `Rscript-ENSEMBLE/results/`, which is excluded from version control and can be regenerated at any time.

No models are re-trained during this step; the pre-trained models in `model/multi/` are loaded directly, so results are reproducible across runs.

Further details are documented in [`Rscript-ENSEMBLE/README.md`](Rscript-ENSEMBLE/README.md).

---

## Key Findings

The workflow demonstrated:

- Automated and reproducible processing of low-coverage whole-genome sequencing (lcWGS) data from plasma cfDNA.
- Integration of sequencing quality control, read alignment, BAM processing, and copy-number analysis within a single Snakemake workflow.
- Scalable cohort-level processing through parallel execution using Snakemake.
- Approximately **4.4-fold reduction in total processing time** when using parallel Snakemake execution compared with sequential execution across 25 samples.
- Integration of cfDNA fragmentomic features with supervised machine learning for pediatric cancer detection and subtype classification.
- Evaluation of four machine learning classifiers: **K-Nearest Neighbors (KNN), Support Vector Machine (SVM), Random Forest (RF), and XGBoost**.
- Random Forest demonstrated the strongest overall performance among the individual classifiers.
- Hard Voting ensemble classification provided competitive performance across the evaluated classification tasks.
- End-motif proportion features at the **3′ fragment terminus** were consistently identified as important predictors across classification tasks.
- The workflow provides a reproducible framework for automated cfDNA fragmentomics analysis and machine learning-based pediatric cancer classification.

---

## Limitations

The current repository version has several limitations:

- The workflow currently uses **paired-end FASTQ files as the primary input format**.
- Read alignment is performed within the workflow using BWA-MEM.
- Pre-aligned BAM files are not currently supported as the primary input format in the released workflow.
- Model evaluation was performed using an internal train/test framework rather than an independent external validation cohort.
- Healthy control samples were obtained primarily from publicly available datasets generated at different sequencing depths, which may introduce potential batch or coverage-related effects.
- The cancer cohort consisted primarily of relapsed, refractory, or progressive pediatric cancer cases.
- The study included two major tumor categories: brain tumors and sarcomas.
- The relatively small number of cancer samples, particularly within individual tumor subtypes, may limit the generalizability of the multiclass classification models.
- Larger, independently collected, and prospectively matched cohorts are required to further validate model robustness and establish clinical utility.
- The current workflow should be considered a research and computational analysis framework rather than a clinically validated diagnostic tool.

---

## Privacy and Data Security

Certain source code files within this project cannot be shared because the project involves the collection of actual circulating cell-free DNA (cfDNA) data from patients, which constitutes sensitive personal information.

---

## Acknowledgement

We would like to acknowledge:

- The patients and families who participated in the INFORM registry.
- The researchers and clinical teams involved in the INFORM study.
- The Hopp Children's Cancer Center Heidelberg (KiTZ).
- The German Cancer Research Center (DKFZ).
- Chulabhorn Royal Academy.
- King Mongkut's University of Technology Thonburi (KMUTT).
- The institutions and researchers who generated and contributed the publicly available datasets used as healthy controls.
- The developers and maintainers of the open-source bioinformatics and machine learning tools used in this project.

---

## License

This repository is intended for research and academic purposes.

Please refer to the repository license file for the specific terms and conditions governing the use, modification, and redistribution of the source code.

Patient-derived sequencing data and other sensitive clinical information are **not included in this repository**.

Users are responsible for ensuring that any patient-derived genomic data used with this workflow are handled in accordance with applicable institutional policies, ethical requirements, data-use agreements, and data-protection regulations.
