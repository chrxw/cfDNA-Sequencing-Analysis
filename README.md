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
- [Privacy and Data Security](#privacy-and-data-security)

## Technologies

- **MobaXterm**: Used for providing an enhanced terminal for managing remote servers, file transfers, and network tools.

- **GitHub**: Used for version control, collaboration, and repository hosting to manage code and documentation.

- **Snakemake**: Used for workflow management and automating bioinformatics data processing pipelines.

- **Google Cloud Platform**: Used for cloud services, including computing resources, storage, and web application deployment.

- **Django Backend**: Used for developing the backend of the web application, managing APIs, and handling server-side logic.

- **React Frontend**: Used for developing the frontend of the web application, creating dynamic and interactive user interfaces.

- **PostgreSQL**: Used as the database system for storing and managing bioinformatics data and application metadata.

## Installation
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

## Privacy and Data Security
Certain source code files within this project cannot be shared because the project involves the collection of actual circulating cell-free DNA (cfDNA) data from patients, which constitutes sensitive personal information. However, we can provide a comprehensive explanation of the web application's functionality based on the available source code.
