# Install and load necessary packages
library(tinytex)
library(rmarkdown)
library(knitr)

# Create an RMarkdown file content as a string
rmarkdown_content <- '
---
title: "Prediction Report"
output: pdf_document
---

## Predictions

```{r predictions_chunk, results="asis", echo=FALSE}
# Display predictions

cat("This prediction is the outcome of a machine learning process utilizing support vector machines (SVM), k-nearest neighbors (KNN), and extreme gradient boosting (XGBoost) algorithms. \n")
cat("\nWorkflow name:", user_filenames, "\n")

predictions <- readRDS(paste0("gs://home/chrwan_ja/", user_filenames, "/output/", user_filenames, "_result", ".rds"))

knitr::kable(predictions, caption = "Predictions by Different Models")

user_data <- readRDS(cfdna_df, file = paste0("gs://home/chrwan_ja/", user_filenames, "/output/", 
                                             user_filenames, "_BAM.rds"))
                                             
user_data_transposed <- as.data.frame(t(user_data))
colnames(user_data_transposed)[1] <- "Parameter"

knitr::kable(user_data_transposed, caption = "Processed Parameters from User")
'

temp_rmd <- tempfile(fileext = ".Rmd")
writeLines(rmarkdown_content, con = temp_rmd)

output_file <- paste0("/", user_filenames, "_result", ".pdf")
output_dir <- paste0("gs://home/chrwan_ja/", user_filenames)

rmarkdown::render(
  input = temp_rmd,
  output_file = output_file,
  output_dir = output_dir
)

# -------------------------------------------------------------------------#

### TSV
# Define the file path for the combined .tsv file
output_tsv_combined <- paste0(output_dir, "/", user_filenames, "_result.tsv")

# Open the file connection
file_conn <- file(output_tsv_combined, "w")

# Write user_data with attributes aligned with values
for (i in 1:nrow(user_data)) {
  cat("Parameter\tValue\n", file = file_conn, append = TRUE)
  for (col_name in names(user_data)) {
    # Write attribute and its value to the file
    cat(col_name, "\t", user_data[[col_name]][i], "\n", file = file_conn)
  }
  # Add an empty line between rows (if needed)
  cat("\n", file = file_conn)
}

# Append an empty line to separate the dataframes
cat("\n", file = file_conn)

# Append the predictions dataframe to the same .tsv file
write.table(predictions, file = file_conn, sep = "\t", quote = FALSE, row.names = FALSE, col.names = TRUE, append = TRUE)

# Close the file connection
close(file_conn)
