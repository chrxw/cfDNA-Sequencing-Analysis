## Import data
# Load Library
library(dplyr)
library(caret)
library(gridExtra)
library(gtools)

# Initialize an empty list to store dataframes
dataframe_list <- list()

rds_directory <- "path/to/your/RDS/file"

rds_files <- mixedsort(list.files(path = rds_directory, pattern = "\\.rds$", full.names = TRUE))

dataframe_list <- lapply(rds_files, readRDS)

# Merge all dataframes into one
df <- bind_rows(dataframe_list)
dataframe <- df[, !names(df) %in% c("sample_id")]
dataframe$tumor_type[dataframe$tumor_type == "Hematolgical malignancies"] <- "Hematological.malignancies"
dataframe$tumor_type[dataframe$tumor_type == "Brain tumors"] <- "Brain.tumors"
dataframe$tumor_type[dataframe$tumor_type == "None"] <- "Healthy"
dataframe$tumor_type[dataframe$tumor_type == "Healthy control"] <- "Healthy"
dataframe$tumor_type[dataframe$tumor_type %in%
                       c("Neuroblastoma", "Hematological.malignancies", "Others")] <- "Others"

dataframe <- dataframe[dataframe$tumor_type != "Others", ]

# -------------------------------------------------------------------------#

## Data Exploration
# Check the structure and content of the merged dataframe
str(dataframe)
head(dataframe)
dim(dataframe)
summary(dataframe)

# -------------------------------------------------------------------------#

## Data Preprocessing
# Feature Selection
source("cfDNA-Sequencing-Analysis/Rscript-ML/ML_feature_normal.R")
# One-hot Encoding & Z-score Standardization
source("cfDNA-Sequencing-Analysis/Rscript-ML/ML_encode_normal.R")
# Data Splitting
source("cfDNA-Sequencing-Analysis/Rscript-ML/ML_dataset_normal.R")

# Machine Learning
# KNN setting
source("cfDNA-Sequencing-Analysis/Rscript-ML/ML_KNN_normal.R")
# SVM setting
source("cfDNA-Sequencing-Analysis/Rscript-ML/ML_SVM_normal.R")
# XGBoost setting
source("cfDNA-Sequencing-Analysis/Rscript-ML/ML_XGBoost_normal.R")
# Random Forest setting
source("cfDNA-Sequencing-Analysis/Rscript-ML/ML_RF_normal.R")
# Model Calling
source("cfDNA-Sequencing-Analysis/Rscript-ML/ML_Calling_normal.R")
