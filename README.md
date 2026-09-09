# Automated Snakemake Workflow for cfDNA Fragmentomics and Machine Learning-Based Pediatric Cancer Classification

An automated and reproducible Snakemake-based workflow for low-coverage whole-genome sequencing (lcWGS) analysis of circulating cell-free DNA (cfDNA), integrating quality control, read alignment, BAM processing, copy-number analysis, fragmentomic feature extraction, and machine learning-based pediatric cancer classification.

## Table of Contents

- [Introduction](#introduction)
- [Workflow Overview](#workflow-overview)
- [Study Cohort](#study-cohort)
- [Prerequisites](#prerequisites)
- [Technologies](#technologies)
- [cfDNA Feature Extraction and Machine Learning](#cfdna-feature-extraction-and-machine-learning)
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

## cfDNA Feature Extraction and Machine Learning

This repository contains the R-based workflow for **cfDNA feature extraction and machine learning analysis**, covering the process from BAM files generated by the upstream cfDNA sequencing analysis workflow through final model evaluation.

The workflow is divided into two main components:

* `Rscript-Main/` — processes BAM files and extracts cfDNA fragmentomic features to generate the feature dataframe used for downstream analysis.
* `Rscript-ML/` — performs feature preprocessing, dataset splitting, machine learning model training, and evaluation.

### Workflow

```text
BAM files
(from the cfDNA sequencing analysis workflow)
        |
        v
Rscript-Main/
BAM processing and feature extraction
        |
        v
Feature dataframe
        |
        v
Rscript-ML/
Feature preprocessing
        |
        v
Feature selection / encoding / normalization
        |
        v
Train / Validation / Test split
        |
        v
Model training and hyperparameter tuning
        |
        +------------------+
        |                  |
       KNN                SVM
        |                  |
     XGBoost          Random Forest
        |                  |
        +--------+---------+
                 |
                 v
        Final test evaluation
```

### `Rscript-Main/` - BAM Processing and Feature Extraction

`Rscript-Main/` contains the scripts used to process BAM files generated from the upstream cfDNA sequencing analysis workflow.

BAM files are processed using [`cfdnakit`](https://github.com/Pitithat-pu/cfdnakit) and sequence-processing functions from **Biostrings** to extract cfDNA fragmentomic features.

#### Extracted features

The extracted features include:

* **Fragment length distribution**

  * Modal fragment length (`isize_peak`)
  * Short-to-long fragment ratio (`sl_ratio`)
  * Fragment length category (`isize_label`)
* **5′ and 3′ end-motif profiles**

  * Motif proportion features
  * Motif identity features
  * Forward, reverse, and combined strand information
* **Tumour burden estimates**

  * ctDNA fraction
  * cfdnakit ctDNA Estimation Score (CES)

For end-motif analysis, fragment sequences are processed according to strand orientation, with reverse-strand sequences reverse-complemented before motif extraction. The first and last four nucleotides are used to characterize the 5′ and 3′ end motifs.

The output of this stage is the **feature dataframe** used as the input for the machine learning workflow.

For details on BAM processing and feature extraction, see [`Rscript-Main/README.md`](Rscript-Main/README.md).

### `Rscript-ML/` - Preprocessing and Machine Learning

`Rscript-ML/` contains the R scripts for preprocessing the feature dataframe and performing machine learning analysis.

The workflow includes:

#### 1. Feature preparation

* Prepare the extracted cfDNA features
* Define the classification targets
* Prepare datasets for each classification task

#### 2. Feature selection and preprocessing

* Perform task-specific feature selection
* Encode categorical variables using one-hot encoding
* Standardize numerical variables using Z-score normalization

#### 3. Dataset splitting

* Training set
* Validation set
* Test set

#### 4. Model training and tuning

* K-Nearest Neighbors (KNN)
* Support Vector Machine (SVM) with a radial basis function kernel
* Random Forest (RF)
* eXtreme Gradient Boosting (XGBoost)

#### 5. Model evaluation

* Evaluate the final models using the held-out test set
* Calculate classification performance metrics
* Generate confusion matrices and ROC/AUC results

The preprocessing and model-development workflow is designed to prevent data leakage. Feature selection and model selection are performed using the model-development data, while the held-out test set remains unseen until final evaluation.

For detailed instructions and individual scripts, see [`Rscript-ML/README.md`](Rscript-ML/README.md).

### Classification Tasks

Four classification tasks are evaluated:

| Task                  | Classification                                 |
| --------------------- | ---------------------------------------------- |
| **Normal**            | Healthy controls vs. all tumors                |
| **Binary - Brain**    | Healthy controls vs. brain tumors              |
| **Binary - Sarcomas** | Healthy controls vs. sarcomas                  |
| **Multiclass**        | Healthy controls vs. brain tumors vs. sarcomas |

### Machine Learning Models

Four supervised machine learning models are implemented:

| Model       | Algorithm                                                |
| ----------- | -------------------------------------------------------- |
| **KNN**     | K-Nearest Neighbors                                      |
| **SVM**     | Support Vector Machine with radial basis function kernel |
| **XGBoost** | eXtreme Gradient Boosting                                |
| **RF**      | Random Forest                                            |

Model training and hyperparameter tuning are performed using the `caret` framework with cross-validation. The selected models are subsequently evaluated on the independent test set.

### Model Evaluation

Model performance is evaluated using the held-out test set.

Evaluation includes:

* Accuracy
* 95% confidence interval
* Sensitivity
* Specificity
* Precision
* Recall
* F1-score
* ROC analysis
* Area under the ROC curve (AUC)
* Confusion matrix

For multiclass classification, appropriate macro-averaged metrics are used for overall performance assessment.

### R Packages

The workflow is implemented in R and uses packages including:

```r
install.packages(c(
  "tidyverse",
  "Biostrings",
  "caret",
  "pROC",
  "randomForest",
  "xgboost",
  "e1071",
  "kernlab",
  "ranger",
  "openxlsx",
  "ggplot2"
))
```

The `cfdnakit` package is used for cfDNA fragmentomic feature extraction.

### Input Data

BAM files used by `Rscript-Main/` are generated by the upstream **cfDNA sequencing analysis workflow** and are not included in this repository.

Patient-derived data, BAM files, and other restricted research data are excluded from version control.

The machine learning workflow in `Rscript-ML/` uses the feature dataframe generated from the BAM-processing step. An existing feature dataframe can therefore be used directly without rerunning BAM processing.

### Reproducibility

Random seeds are specified where applicable to support reproducibility of dataset splitting, model training, and hyperparameter tuning.

The repository contains the R scripts defining the feature extraction, preprocessing, machine learning, and evaluation workflows. Restricted patient-derived data and generated analysis results are not included in version control.

### Documentation

Detailed documentation for each component is available in:

* [`Rscript-Main/README.md`](Rscript-Main/README.md) — BAM processing and cfDNA feature extraction
* [`Rscript-ML/README.md`](Rscript-ML/README.md) — feature preprocessing, dataset splitting, machine learning, and model evaluation

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
