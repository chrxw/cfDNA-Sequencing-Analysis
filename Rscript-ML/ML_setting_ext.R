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
# Feature Selection - significant_df_ext
source("cfDNA-Sequencing-Analysis/Rscript-ML/ML_feature_ext.R")
# One-hot Encoding & Z-score Standardization - processed_dataframe_ext
source("cfDNA-Sequencing-Analysis/Rscript-ML/ML_encode_ext.R")
# Data Splitting
source("cfDNA-Sequencing-Analysis/Rscript-ML/ML_dataset_ext.R")

# Machine Learning
# KNN setting
source("cfDNA-Sequencing-Analysis/Rscript-ML/ML_KNN_ext.R")
# SVM setting
source("cfDNA-Sequencing-Analysis/Rscript-ML/ML_SVM_ext.R")
# XGBoost setting
source("cfDNA-Sequencing-Analysis/Rscript-ML/ML_XGBoost_ext.R")
# Random Forest setting
source("cfDNA-Sequencing-Analysis/Rscript-ML/ML_RF_ext.R")
# Model Calling
source("cfDNA-Sequencing-Analysis/Rscript-ML/ML_Calling_ext.R")
