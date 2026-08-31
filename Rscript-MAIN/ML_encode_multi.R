## Encoding & Z-score Standardization
# Load necessary libraries
library(caret)
library(recipes)

# -------------------------------------------------------------------------#

## First recipe: Encode both predictor variables and target variable
# One-hot encoding
rec_encode <- recipe(tumor_type ~ ., data = significant_df_multi) %>%
  step_dummy(all_nominal_predictors())  # One-hot encode categorical features, including the target variable

rec_encode_prep <- prep(rec_encode, training = significant_df_multi)
encoded_dataframe_multi <- bake(rec_encode_prep, new_data = significant_df_multi)

## Second recipe: Standardize predictor variables only
# Z-score standardization
rec_standardize <- recipe(~ ., data = encoded_dataframe_multi) %>%
  step_zv(all_numeric()) %>%  # Remove columns with zero variance
  step_center(all_numeric()) %>%  # Center numerical features
  step_scale(all_numeric())  # Scale numerical features

rec_standardize_prep <- prep(rec_standardize, training = encoded_dataframe_multi)
processed_dataframe_multi <- bake(rec_standardize_prep, new_data = encoded_dataframe_multi)

processed_dataframe_multi$tumor_type <- dataframe$tumor_type
processed_dataframe_multi$tumor_label <- dataframe$tumor_label