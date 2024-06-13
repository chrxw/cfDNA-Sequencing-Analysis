## Get tumor type
# Load package
library(readxl)

# Specify the file path
sample_data <- "/omics/odcf/analysis/OE0290_projects/pediatric_tumor/whole_genome_sequencing_CRAsnakemake/HDS_project/File Management_ML.xlsx"

# Read the Excel file
data <- read_excel(sample_data, col_names = TRUE)
data

tumor_type <- as.list(data[[4]])
