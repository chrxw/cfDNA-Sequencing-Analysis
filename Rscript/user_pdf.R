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

# predictions <- readRDS(paste0("gs://home/chrwan_ja/", user_filenames, "/output/", user_filenames, "result", ".rds"))

knitr::kable(predictions, caption = "Predictions by Different Models")
'

temp_rmd <- tempfile(fileext = ".Rmd")
writeLines(rmarkdown_content, con = temp_rmd)

output_file <- paste0(user_filenames, "/output/", user_filenames, "result", ".pdf")
output_dir <- paste0("gs://home/chrwan_ja/", user_filenames, "/output/", 
                     user_filenames, ".rds")

rmarkdown::render(
  input = temp_rmd,
  output_file = output_file,
  output_dir = output_dir
)
