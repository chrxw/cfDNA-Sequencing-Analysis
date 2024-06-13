# Install and load necessary packages
library(tinytex)
library(rmarkdown)
library(knitr)
library(kableExtra)

# -------------------------------------------------------------------------#

### PDF
# Create an RMarkdown file content as a string
rmarkdown_content <- '
---
title: "Prediction Report"
output: pdf_document
---

## Prediction

```{r predictions_chunk, results="asis", echo=FALSE}
# Display predictions

cat("This prediction is the outcome of a machine learning process utilizing support vector machines (SVM), k-nearest neighbors (KNN), and extreme gradient boosting (XGBoost) algorithms. \\n")
cat("\\nWorkflow name:", user_filenames, "\\n")

metrics <- readRDS(paste0("/home/chrwan_ja/output/", user_filenames, "/", user_filenames, "_metrics", ".rds"))

predictions <- readRDS(paste0("/home/chrwan_ja/output/", user_filenames, "/", user_filenames, "_result", ".rds"))

knitr::kable(metrics, caption = "Model Metrics")
knitr::kable(predictions, caption = "Predictions by Different Models")

user_data <- readRDS(paste0("/home/chrwan_ja/output/", user_filenames, "/", user_filenames, "_BAM.rds"))
                           
params_df <- data.frame(Parameter = character(), Value = character(), stringsAsFactors = FALSE)
for (i in 1:nrow(user_data)) {
  for (col_name in names(user_data)) {
    value <- user_data[[col_name]][i]
    if (is.numeric(value) && grepl("\\\\.[0-9]{6,}", as.character(value))) {
      value <- sprintf("%.5f", value)  # Format to 5 decimal places
    }
    params_df <- rbind(params_df, data.frame(Parameter = col_name, Value = value, stringsAsFactors = FALSE))
  }
}
rownames(params_df) <- NULL

user_data_transposed <- as.data.frame(t(user_data))
colnames(user_data_transposed)[1] <- "Parameter"

knitr::kable(params_df, caption = "Processed Parameters from User")
'

temp_rmd <- tempfile(fileext = ".Rmd")
writeLines(rmarkdown_content, con = temp_rmd)

output_file <- paste0("/", user_filenames, "_result", ".pdf")
output_dir <- paste0("/home/chrwan_ja/output/", user_filenames)

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

# Append the predictions dataframe to the same .tsv file
cat("Model Metrics\n", file = file_conn)
write.table(metrics, file = file_conn, sep = "\t", quote = FALSE, row.names = FALSE, col.names = TRUE, append = TRUE)
cat("\n", file = file_conn)

# Append the predictions dataframe to the same .tsv file
cat("Predictions by Different Models\n", file = file_conn)
write.table(predictions, file = file_conn, sep = "\t", quote = FALSE, row.names = FALSE, col.names = TRUE, append = TRUE)
cat("\n", file = file_conn)

# Write user_data with attributes aligned with values
cat("Processed Parameters from User\n", file = file_conn)
# Write the data frame to a .tsv file
write.table(params_df, file = file_conn, sep = "\t", quote = FALSE, row.names = FALSE, col.names = TRUE, append = TRUE)

# Close the file connection
close(file_conn)

# -------------------------------------------------------------------------#

### HTML
# Generate HTML for text content with Google-inspired style
text_content <- paste(
  '<div style="text-align: center; margin-bottom: 20px; font-family: Arial, sans-serif;">',
  '<h1 style="color: #094067;">Prediction Report</h1>',
  '</div>',
  '<div style="text-align: left; margin-bottom: 20px; margin-left: 100px; font-family: Arial, sans-serif; color: #666;">',
  '<p>This prediction is the outcome of a machine learning process utilizing support vector machines (SVM), k-nearest neighbors (KNN), and extreme gradient boosting (XGBoost) algorithms.</p>',
  '<p>Workflow name: ', user_filenames, '</p>',
  '</div>'
)

# Apply styling to tables using kableExtra
styled_kable <- function(df, title) {
  kable(df, format = "html", table.attr = "style='border-collapse: collapse; border: 1px solid #ddd;'") %>% # Add border style
    kable_styling(full_width = FALSE, bootstrap_options = "striped", font_size = 14) %>%
    add_header_above(c(setNames(ncol(df), title)), bold = TRUE, color = "white", background = "#5f6c7b") %>%
    column_spec(1:ncol(df), border_right = TRUE) %>%
    row_spec(0, bold = TRUE, background = "#3da9fc", color = "white") # Highlight header row
}

# Generate HTML for each table with titles
html1 <- styled_kable(metrics, "Model Metrics")
html2 <- styled_kable(predictions, "Predictions by Different Models")
html3 <- styled_kable(params_df, "Processed Parameters from User")

# Generate HTML for each table with titles and specific heights
html1 <- paste(
  '<div style="overflow-y: auto; margin-left: 400px">',
  styled_kable(metrics, "Model Metrics"),
  '</div>'
)

html2 <- paste(
  '<div style="overflow-y: auto;">',
  styled_kable(predictions, "Predictions by Different Models"),
  '</div>'
)

html3 <- paste(
  '<div style="overflow-y: auto; margin-right: 400px">',
  styled_kable(params_df, "Processed Parameters from User"),
  '</div>'
)

# Combine the HTML tables and text content using HTML divs
html_combined <- paste(
  text_content,
  '<div style="display: flex; text-align: center; justify-content: space-between; font-family: Arial, sans-serif; color: #666;"">',
  html1,
  html2,
  html3,
  '</div>'
)

# Write the combined HTML to a file
write(html_combined, file = paste0(output_dir, "/", user_filenames, "_result.html"))
