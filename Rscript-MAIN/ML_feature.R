# Load required library
library(stats)

# Separate column by class
numeric_df <- dataframe_X[, (sapply(dataframe_X, class)) %in% c("numeric", "integer")]
numeric_df$tumor_label <- dataframe_X$tumor_label
character_df <- dataframe_X[, (sapply(dataframe_X, class)) == "character"]

# -------------------------------------------------------------------------#

### T-test
# Initialize a list to store p-values for numerical features
numeric_pvalues <- list()

# Perform t-tests for each numerical feature against the target variable
for (col in names(numeric_df)[-ncol(numeric_df)]) {
  # Check if the variance of the data is non-zero for both groups
  var_tumor <- var(numeric_df[[col]][numeric_df$tumor_label == "tumor"])
  var_no_tumor <- var(numeric_df[[col]][numeric_df$tumor_label == "no_tumor"])
  if (var_tumor > 0 && var_no_tumor > 0) {
    t_test <- t.test(numeric_df[[col]] ~ numeric_df$tumor_label)
    numeric_pvalues[[col]] <- t_test$p.value
  } else {
    numeric_pvalues[[col]] <- NA
  }
}

# Remove NA values from numeric p-values
numeric_pvalues <- numeric_pvalues[!is.na(numeric_pvalues)]

# Print the numeric p-values
print(numeric_pvalues)

# -------------------------------------------------------------------------#

### Fisher's Exact Test
# Initialize a list to store p-values for categorical features
categorical_pvalues <- list()

# Convert character columns to factors and harmonize factor levels
character_df[] <- lapply(character_df, as.factor)

# Identify all unique levels across the specified columns
combined_levels <- unique(c(
  character_df$motif_peak_fwd_1,
  character_df$motif_peak_fwd_2,
  character_df$motif_peak_rev_1,
  character_df$motif_peak_rev_2,
  character_df$motif_peak_1,
  character_df$motif_peak_2
))

# Convert specified columns to factors using the combined levels
character_df <- character_df %>%
  mutate(across(c(motif_peak_fwd_1, motif_peak_fwd_2, motif_peak_rev_1, motif_peak_rev_2, motif_peak_1, motif_peak_2),
                ~ factor(.x, levels = combined_levels)))

# Perform Fisher's Exact Test for each categorical feature against the target variable
for (col in names(character_df)[-length(names(character_df))]) {
  test_result <- fisher.test(table(character_df[[col]], character_df$tumor_label))
  categorical_pvalues[[col]] <- test_result$p.value
}

# Remove NA values from categorical p-values
categorical_pvalues <- categorical_pvalues[!is.na(categorical_pvalues)]

# Print the categorical p-values
print(categorical_pvalues)

# -------------------------------------------------------------------------#

# Combine numeric and categorical p-values
all_pvalues <- c(numeric_pvalues, categorical_pvalues)

# Create a data frame with feature names and p-values
pvalues_df <- data.frame(
  feature = names(all_pvalues),
  p_value = unlist(all_pvalues),
  stringsAsFactors = FALSE
)

# Remove NA values
pvalues_df <- pvalues_df[complete.cases(pvalues_df), ]

# Arrange in ascending order of p-values
pvalues_df <- pvalues_df[order(pvalues_df$p_value), ]

# Add the interpretation column
pvalues_df$result <- ifelse(pvalues_df$p_value < 0.05, "Significant", "Not Significant")

# Filter pvalues_df to include only significant features
significant_pvalues_df <- pvalues_df[pvalues_df$p_value < 0.05, ]

# -------------------------------------------------------------------------#

# Filter pvalues_df to include only significant features
significant_pvalues_df <- pvalues_df[pvalues_df$p_value < 0.05, ]

# Get the names of significant features
significant_feature_names <- significant_pvalues_df$feature

# Create a new dataframe with only the significant features and the target variable
significant_df <- dataframe_X[, c("tumor_label", significant_feature_names)]

# -------------------------------------------------------------------------#

create_feature_importance_plot <- function(significant_pvalues_df) {
  significant_pvalues_df$importance <- -log10(significant_pvalues_df$p_value)
  
  plot <- ggplot(significant_pvalues_df, aes(x = reorder(feature, importance), y = importance)) +
    geom_bar(stat = "identity", fill = "lightgreen") +
    coord_flip() +
    xlab("Feature") +
    ylab("-log10(p-value)") +
    ggtitle("Feature Importance based on -log10(p-value)") +
    theme_minimal()
}

feature_plot <- create_feature_importance_plot(significant_pvalues_df)

grid.arrange(feature_plot)