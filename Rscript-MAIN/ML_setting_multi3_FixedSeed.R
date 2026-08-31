## Import data
# Load Library
library(dplyr)
library(caret)
library(gridExtra)
library(gtools)

# Initialize an empty list to store dataframes
dataframe_list <- list()

rds_directory <- "D:/CPE407/RDS"
rds_directory_new1 <- "D:/CPE407/THESIS/Dataset/NewControl/RDS39_new"
rds_directory_new2 <- "D:/CPE407/THESIS/Dataset/NewControl/RDS80"

rds_files <- mixedsort(list.files(path = rds_directory, pattern = "\\.rds$", full.names = TRUE))
rds_files_new1 <- mixedsort(list.files(path = rds_directory_new1, pattern = "\\.rds$", full.names = TRUE))
rds_files_new2 <- mixedsort(list.files(path = rds_directory_new2, pattern = "\\.rds$", full.names = TRUE))

all_rds_files <- c(rds_files, rds_files_new1, rds_files_new2)
dataframe_list <- lapply(all_rds_files, readRDS)

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
# Feature Selection - significant_df
source("D:/CPE407/THESIS/ML_feature_multi.R")
# One-hot Encoding & Z-score Standardization - processed_dataframe_multi
source("D:/CPE407/THESIS/ML_encode_multi.R")
# Data Splitting
source("D:/CPE407/THESIS/ML_dataset_multi3_seed.R")

# Machine Learning
# KNN setting
source("D:/CPE407/THESIS/ML_KNN_multi.R")
# SVM setting
source("D:/CPE407/THESIS/ML_SVM_multi.R")
# XGBoost setting
source("D:/CPE407/THESIS/ML_XGBoost_multi.R")
# Random Forest setting
source("D:/CPE407/THESIS/ML_RF_multi.R")
# Model Calling
source("D:/CPE407/THESIS/ML_Calling_multi3_seed.R")
