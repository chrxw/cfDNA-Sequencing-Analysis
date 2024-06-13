## Get tumor type
# Load package
library(readxl)

# Specify the file path
sample_data <- "path/to/your/file.xlsx" # tumor type label

# Read the Excel file
data <- read_excel(sample_data, col_names = TRUE)
data

tumor_type <- as.list(data[[4]])
