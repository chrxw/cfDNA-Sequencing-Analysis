## Import data
# Load Library
library(dplyr)
library(caret)
library(gridExtra)
library(gtools)

# Initialize an empty list to store dataframes
dataframe_list <- list()

rds_directory <- "/omics/odcf/analysis/OE0290_projects/pediatric_tumor/whole_genome_sequencing_CRAsnakemake/HDS_project/MachineLearning/RDS"
rds_files <- list.files(path = rds_directory, pattern = "\\.rds$", full.names = TRUE)
rds_files <- mixedsort(rds_files)

for (i in seq_along(rds_files)) {
  dataframe_list[[i]] <- readRDS(rds_files[i])
}

# Merge all dataframes into one
df <- bind_rows(dataframe_list)
dataframe <- df[, !names(df) %in% c("sample_id")]

# For Binary-classification
dataframe_X <- dataframe[, !names(dataframe) %in% c("tumor_type")]

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
source("/omics/odcf/analysis/OE0290_projects/pediatric_tumor/whole_genome_sequencing_CRAsnakemake/HDS_project/MachineLearning/R_setting/ML_feature.R")

# One-hot Encoding & Z-score Standardization - processed_dataframe
source("/omics/odcf/analysis/OE0290_projects/pediatric_tumor/whole_genome_sequencing_CRAsnakemake/HDS_project/MachineLearning/R_setting/ML_encode.R")

# Data Splitting
source("/omics/odcf/analysis/OE0290_projects/pediatric_tumor/whole_genome_sequencing_CRAsnakemake/HDS_project/MachineLearning/R_setting/ML_dataset.R")