### Load Model
# Load required library
library(caret)
library(recipes)

# Model path
model_path <- "gs://csa_upload/model"
ml_model <- list.files(model_path, pattern = "\\.rds$", full.names = TRUE)

# Load model
models <- lapply(ml_model, readRDS)
names(models) <- gsub("\\.rds$", "", basename(ml_model))
model_type <- names(models)

# -------------------------------------------------------------------------#

# Load new data provided by the user
user_data <- readRDS("gs://home/chrwan_ja/", user_filenames, "/output/", 
                    user_filenames, ".rds")

# Mock-up tumor_label for pre-processing
user_data$tumor_label <- "tumor"

dataframe_X <- readRDS("gs://home/chrwan_ja/Rscript/dataframe_X.rds")
combined_data <- bind_rows(dataframe_X, user_data)

new_df <- combined_data[, !names(combined_data) %in% c("sample_id")]
new_df_X <- new_df[, !names(new_df) %in% c("tumor_type")]

# Pre-processing
source("gs://home/chrwan_ja/Rscript/ML_user_preprocess.R")

# Get only user_data
user_df <- tail(processed_dataframe, 1)

# -------------------------------------------------------------------------#

# List to store predictions
all_predictions <- list()

# Loop through each model
for (i in seq_along(models)) {
  # Make predictions using the current model
  current_model <- models[[i]]
  current_predictions <- predict(current_model, newdata = user_df)
  
  # Store predictions in the list
  all_predictions[[i]] <- current_predictions
}

# Display the predictions
all_predictions

# -------------------------------------------------------------------------#

# Function to create a data frame for better display
create_prediction_df <- function(predictions) {
  model <- character()
  prediction <- character()
  
  for (i in seq_along(predictions)) {
    model_name <- model_type[i]
    prediction_value <- as.character(predictions[[i]])
    model <- c(model, model_name)
    prediction <- c(prediction, prediction_value)
  }
  
  data.frame(Model = model, Prediction = prediction, stringsAsFactors = FALSE)
}

# Create data frame
prediction_df <- create_prediction_df(all_predictions)
knitr::kable(prediction_df, caption = "Predictions by Different Models")

for (model in names(all_predictions)) {
  cat(paste0("### ", model, "\n\n"))
  cat(paste0("Prediction: ", all_predictions[[model]], "\n\n"))
}

# Export data to RDS file
saveRDS(prediction_df, file = paste0("gs://home/chrwan_ja/", user_filenames, "/output/", 
                                     user_filenames, "result", ".rds"))

# Export PDF
source("gs://home/chrwan_ja/Rscript/user_pdf.R")