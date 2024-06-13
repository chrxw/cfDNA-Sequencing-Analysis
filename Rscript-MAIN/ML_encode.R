## Encoding & Z-score Standardization
# Load necessary libraries
library(caret)
library(recipes)

# -------------------------------------------------------------------------#

## First recipe: Encode both predictor variables and target variable
# One-hot encoding
rec_encode <- recipe(tumor_label ~ ., data = significant_df) %>%
  step_dummy(all_nominal())  # One-hot encode categorical features, including the target variable

rec_encode_prep <- prep(rec_encode, training = significant_df)
encoded_dataframe <- bake(rec_encode_prep, new_data = significant_df)

## Second recipe: Standardize predictor variables only
# Z-score standardization
rec_standardize <- recipe(~ ., data = encoded_dataframe) %>%
  step_zv(all_numeric()) %>%  # Remove columns with zero variance
  step_center(all_numeric()) %>%  # Center numerical features
  step_scale(all_numeric())  # Scale numerical features

rec_standardize_prep <- prep(rec_standardize, training = encoded_dataframe)
processed_dataframe <- bake(rec_standardize_prep, new_data = encoded_dataframe)

processed_dataframe$tumor_label <- dataframe$tumor_label
processed_dataframe <- subset(processed_dataframe, select = -c(tumor_label_tumor))
