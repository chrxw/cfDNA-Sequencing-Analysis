# **Integrating Snakemake Workflow with Advanced Fragmentomics Features for Next-Generation Sequencing Analysis of Cell-Free DNA Identifies Actionable Insights**

Development of a Web Application for Automated Data Production Pipeline for Next-Generation Sequencing (NGS) Analysis of Cell-Free DNA Using Snakemake and Machine Learning to Predict Pediatric cancer, Enhance Analysis Efficiency, and Advance Personalized Medicine with Early-Stage Cancer Probability.

## Table of Contents

- [Introduction](#introduction)
- [Limitation](#limitation)
- [Prerequisites](#prerequisites)
- [Technologies](#technologies)
- [Installation](#installation)
- [Inspiration](#inspiration)

## Introduction

Pediatric cancer originates from genetic abnormalities present from birth to the age of 15. Early screening and diagnosis before the onset of metastasis significantly enhance treatment prospects and overall therapeutic success. However, the conventional approach of tissue biopsy for precise diagnosis and subsequent treatment presents notable challenges owing to its invasive nature. This is especially pertinent in conditions such as brain cancer, where the procedure carries inherent risks. Presently, the advent of liquid biopsy techniques, such as extracting cell-free DNA (cfDNA) from bodily fluids like blood and cerebrospinal fluid, coupled with Next-Generation Sequencing (NGS), offers a promising avenue for non-invasive early detection and genetic profiling.

In this study, we developed an automated workflow to analyze cfDNA data from 185 pediatric cancer patients using NGS. We employed NGS to analyze the physical characteristics of cfDNA fragments (cfDNA fragmentomics), enabling the differentiation of patient samples from normal controls. Furthermore, we implemented and evaluated three machine learning models—Support Vector Machine (SVM), K-Nearest Neighbors (KNN), and XGBoost—to predict the likelihood of cancer occurrence based on cfDNA profiles. Model performance metrics, including sensitivity/recall, specificity, and area under curve (AUC), were utilized for evaluation. 
The integration of technology and predictive analytics not only optimizes the analysis of NGS data but also significantly advances early cancer prediction and personalized medicine. This interdisciplinary approach combines the strengths of technological integration and predictive analytics to streamline NGS data analysis and contribute to the forefront of early cancer prognosis and personalized medical interventions.

## Limitation

- The input file must be in fastq format only.
- Execute each sample.

## Prerequisites

Before starting the project, the following prerequisites installed:

- [Ubuntu](https://ubuntu.com/) or another Linux OS
- [Conda](https://conda.org/)
- [R](https://www.r-project.org/)
- [Python](https://www.python.org/)
- [Django](https://www.djangoproject.com/)
- [Node.js](https://nodejs.org/)
- [React](https://reactjs.org/)
- [Vite](https://vitejs.dev/)

## Technologies

- **MobaXterm**: Used for providing an enhanced terminal for managing remote servers, file transfers, and network tools.

- **GitHub**: Used for version control, collaboration, and repository hosting to manage code and documentation.

- **Snakemake**: Used for workflow management and automating bioinformatics data processing pipelines.

- **Google Cloud Platform**: Used for cloud services, including computing resources, storage, and web application deployment.

- **Django Backend**: Used for developing the backend of the web application, managing APIs, and handling server-side logic.

- **React Frontend**: Used for developing the frontend of the web application, creating dynamic and interactive user interfaces.

- **PostgreSQL**: Used as the database system for storing and managing bioinformatics data and application metadata.

## Installation

Divided into 3 steps as follows.

1. **Prepare the environment for managing bioinformatics files with Snakemake**

    Installing packages in the environment on a cluster involves the following 9 steps:

    1. Clone the [ichorCNA repository](https://github.com/broadinstitute/ichorCNA):

        ```sh
        git clone https://github.com/broadinstitute/ichorCNA.git
        ```

    2. Create a conda environment with r-base and ichorCNA:

        ```sh
        conda create --name env1 r-base bioconda::r-ichorcna=0.3.2
        ```

    3. Install the [R devtools package](https://devtools.r-lib.org/):

        ```sh
        conda install conda-forge::r-devtools
        ```

    4. Install [Snakemake](https://snakemake.readthedocs.io/en/stable/) for workflow management:

        ```sh
        conda install bioconda::snakemake
        ```

    5. Install [FastQC](https://www.bioinformatics.babraham.ac.uk/projects/fastqc/) for quality control of sequencing data:

        ```sh
        conda install bioconda::fastqc
        ```

    6. Install [BWA](https://github.com/lh3/bwa) for aligning sequencing reads:

        ```sh
        conda install bioconda::bwa
        ```

    7. Install [SAMtools](https://github.com/samtools/samtools) for manipulating sequencing data:

        ```sh
        conda install bioconda::samtools
        ```

    8. Install [Picard](https://broadinstitute.github.io/picard/) for manipulating high-throughput sequencing data:

        ```sh
        conda install bioconda::picard
        ```

    9. Install [HMMcopy](https://anaconda.org/bioconda/hmmcopy) for analyzing copy number variations:

        ```sh
        conda install bioconda::hmmcopy
        ```

2. **Prepare the environment for training machine learning models and predicting cancer**

    Packages used for the machine learning process are as follows:

    1. Install [cfdnakit](https://github.com/Pitithat-pu/cfdnakit) for length analysis and Copy-number Alteration (CNA) of cfDNA (circulating free DNA):

        ```r
        if (!requireNamespace("BiocManager", quietly = TRUE))
        install.packages("BiocManager")

        BiocManager::install("cfdnakit")
        ```
    
    2. Install [Biostrings](https://bioconductor.org/packages/release/bioc/html/Biostrings.html) for organizing and analyzing DNA, RNA, and protein sequences, with functions to search, organize, and compare sequences:

        ```r
        if (!require("BiocManager", quietly = TRUE))
        install.packages("BiocManager")
        
        BiocManager::install("Biostrings")
        ```

    3. Install [caret](https://topepo.github.io/caret/index.html) that helps partition data to create datasets for machine learning. It also includes tools for parameter tuning and model evaluation:

        ```r
        install.packages("caret")
        ```

    4. Install [ggplot2](https://ggplot2.tidyverse.org/) for creating highly flexible and beautiful graphs used for creating visualizations in data analysis:

        ```r
        install.packages("ggplot2")
        ```

    5. Install [pROC](https://xrobin.github.io/pROC/) for analyzing and drawing ROC (Receiver Operating Characteristic) graphs to evaluate the performance of classification models:

        ```r
        install.packages("pROC")
        ```

    6. Install [kernlab](https://cran.r-project.org/web/packages/kernlab/index.html) for machine learning that provides Kernel-based models such as SVM and Kernel PCA:

        ```r
        install.packages("kernlab")
        ```

    7. Install [e1071](https://cran.r-project.org/web/packages/e1071/index.html) for machine learning using Support Vector Machine (SVM) models:

        ```r
        install.packages("e1071")
        ```

    8. Install [class](https://www.stats.ox.ac.uk/pub/MASS4/) for machine learning using K-Nearest Neighbors (KNN) models:

        ```r
        install.packages("class")
        ```

    9. Install [xgboost](https://xgboost.readthedocs.io/en/stable/R-package/index.html) for machine learning using XGBoost (Extreme Gradient Boosting) models:

        ```r
        install.packages("xgboost")
        ```

    10. Install [gridExtra](https://cran.r-project.org/web/packages/gridExtra/index.html) that helps organize and arrange graphics created from ggplot2 or other graphs in custom ways:

        ```r
        install.packages("gridExtra")
        ```

    11. Install [gtools](https://github.com/r-gregmisc/gtools) that provides tools for various data manipulations, such as sorting, merging files, and creating custom functions:

        ```r
        install.packages("gtools")
        ```

    12. Install [dplyr](https://dplyr.tidyverse.org/) for high-performance data management used for filtering, sorting, summarizing, and converting data into tables:

        ```r
        install.packages("dplyr")
        ```

    13. Install [recipes](https://recipes.tidymodels.org/) for preparing data for machine learning. It has functions for converting data, parameter adjustment, and data verification:

        ```r
        install.packages("recipes")
        ````

    14. Install [rmarkdown](https://github.com/rstudio/rmarkdown) for creating report documents that can include code, text, and data analysis results in HTML, PDF, and Word formats:

        ```r
        install.packages("rmarkdown")
        ```

    15. Install [knitr](https://yihui.org/knitr/) an rmarkdown companion package for creating reports that can automatically combine R code and results:

        ```r
        install.packages("knitr")
        ```

    16. Install [tinytex](https://github.com/rstudio/tinytex) that helps install LaTeX, a document management system used for creating beautifully formatted PDF documents:

        ```r
        install.packages("tinytex")
        ```

    17. Install [kableExtra](https://github.com/haozhu233/kableExtra) that helps create tables in rmarkdown and knitr by adding flexible and elegant table formatting functionality:

        ```r
        install.packages("kableExtra")
        ```

3. **Web application development**

    The steps for the web application development process are as follows:

    1. **Create a Database**: Set up [PostgreSQL](https://www.postgresql.org/) for storing and managing bioinformatics data and application metadata.

    2. **Create a Cloud Storage** (optional): Use [Google Cloud Storage](https://cloud.google.com/storage?hl=th) for storing large bioinformatics datasets.

    3. **Create a Backend**: Use Django for developing the backend, managing APIs, and handling server-side logic.

    4. **Create a Frontend**: Use React for developing the frontend, creating dynamic and interactive user interfaces.

    5. **Deployment**: Deploy the web application using Google Cloud Platform's Cloud Run for scalable serverless execution.

    #### Notes:
    
    For web application development, there are quite a lot of packages used. It might be better to have separate files for frontend and backend packages. However, here is a brief list:

    - Backend Packages: Django, djangorestframework, psycopg2, etc.
    - Frontend Packages: React, Axios, react-router-dom, etc.

## Inspiration

Frontend design inspired by [Galaxy](https://usegalaxy.org/) and [EPI2ME](https://github.com/epi2me-labs)