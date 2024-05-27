library(recipes)

## Data Preprocessing
# From One-hot Encoding & Z-score Standardization
significant_df <- readRDS("gs://home/chrwan_ja/Rscript/significant_df.rds")

new_dataframe <- new_df_X[, colnames(new_df_X) %in% colnames(significant_df)]
new_dataframe <- new_dataframe[, colnames(significant_df)[colnames(significant_df) %in% colnames(new_df_X)]]
#new_dataframe[] <- lapply(new_dataframe, as.factor)

# One-hot encoding (No label is a must use reference dataset)
rec_encode <- recipe(tumor_label ~ ., data = significant_df) %>%
  step_dummy(all_nominal())

rec_encode_prep <- prep(rec_encode, training = new_dataframe)
encoded_dataframe <- bake(rec_encode_prep, new_data = new_dataframe)

rec_standardize <- recipe(~ ., data = encoded_dataframe) %>%
  step_zv(all_numeric()) %>%  # Remove columns with zero variance
  step_center(all_numeric()) %>%  # Center numerical features
  step_scale(all_numeric())  # Scale numerical features

rec_standardize_prep <- prep(rec_standardize, training = encoded_dataframe)
processed_dataframe <- bake(rec_standardize_prep, new_data = encoded_dataframe)

processed_dataframe <- subset(processed_dataframe, select = -c(tumor_label_tumor))
