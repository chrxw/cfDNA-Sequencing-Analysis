# Load required library
library(stats)
library(ggplot2)
library(reshape2)
library(corrplot)
library(gridExtra)
library(GGally)
library(randomForest)

# Separate column by class
numeric_df_ext <- dataframe[, (sapply(dataframe, class)) %in% c("numeric", "integer")]
numeric_df_ext$tumor_label <- dataframe$tumor_label
character_df_ext <- dataframe[, (sapply(dataframe, class)) == "character"]
character_df_ext <- character_df_ext[, !names(character_df_ext) %in% c("tumor_type")]

feature_df_ext <- cbind(numeric_df_ext, character_df_ext)

# Prepare Data
feature_df_ext$tumor_label <- as.factor(feature_df_ext$tumor_label)

# -------------------------------------------------------------------------#

### T-test
# Initialize a list to store p-values for numerical features
numeric_pvalues <- list()

# Perform t-tests for each numerical feature against the target variable
for (col in names(numeric_df_ext)[-ncol(numeric_df_ext)]) {
  # Check if the variance of the data is non-zero for both groups
  var_tumor <- var(numeric_df_ext[[col]][numeric_df_ext$tumor_label == "tumor"])
  var_no_tumor <- var(numeric_df_ext[[col]][numeric_df_ext$tumor_label == "no_tumor"])
  if (var_tumor > 0 && var_no_tumor > 0) {
    t_test <- t.test(numeric_df_ext[[col]] ~ numeric_df_ext$tumor_label)
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
character_df_ext[] <- lapply(character_df_ext, as.factor)

# Identify all unique levels across the specified columns
combined_levels <- unique(c(
  character_df_ext$motif_peak_fwd_1,
  character_df_ext$motif_peak_fwd_2,
  character_df_ext$motif_peak_rev_1,
  character_df_ext$motif_peak_rev_2,
  character_df_ext$motif_peak_1,
  character_df_ext$motif_peak_2
))

# Convert specified columns to factors using the combined levels
character_df_ext <- character_df_ext %>%
  mutate(across(c(motif_peak_fwd_1, motif_peak_fwd_2, motif_peak_rev_1, motif_peak_rev_2, motif_peak_1, motif_peak_2),
                ~ factor(.x, levels = combined_levels)))

# Perform Fisher's Exact Test for each categorical feature against the target variable
for (col in names(character_df_ext)[-length(names(character_df_ext))]) {
  test_result <- fisher.test(table(character_df_ext[[col]], character_df_ext$tumor_label))
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
significant_pvalues_df_ext <- pvalues_df[pvalues_df$p_value < 0.05, ]

# -------------------------------------------------------------------------#

# Get the names of significant features
significant_feature_names <- significant_pvalues_df_ext$feature

# Create a new dataframe with only the significant features and the target variable
significant_df_ext <- dataframe[, c("tumor_label", significant_feature_names)]

# ----------------------------------IEEE ACCESS FORMAT---------------------------------------#

# Fix font
library(Cairo)

windowsFonts(Times = windowsFont("Times New Roman"))

theme_set(
  theme_minimal(base_family = "Times", base_size = 9) +
    theme(panel.grid = element_blank())
)

theme_set( theme_minimal(base_family = "Times New Roman", base_size = 9) +
             theme(panel.grid = element_blank()) )

# -------------------------------------------------------------------------#
# Feature Importance Plot
create_feature_importance_plot <- function(significant_pvalues_df_ext) {
  significant_pvalues_df_ext$importance <- -log10(significant_pvalues_df_ext$p_value)
  
  plot <- ggplot(significant_pvalues_df_ext, aes(x = reorder(feature, importance), y = importance)) +
    geom_bar(stat = "identity", fill = "lightpink", width = 0.6) +
    geom_text(aes(label = round(importance, 2)), size = 2, family = "Times") +
    coord_flip() +
    xlab("Feature") +
    ylab("-log10 (p-value)") +
    ggtitle("Statistical Significance on -log10 (p-value)") +
    theme(plot.title = element_text(hjust = 0.5))
  
  return(plot)
}

feature_plot_ext <- create_feature_importance_plot(significant_pvalues_df_ext)

# -------------------------------------------------------------------------#
# Correlation Heatmap (for numeric features)
# Compute correlation matrix
numeric_features_ext <- numeric_df_ext[, names(numeric_df_ext) %in% significant_feature_names]
cor_matrix <- cor(numeric_features_ext, use = "pairwise.complete.obs")

# Melt correlation matrix for ggplot2
cor_melted <- reshape2::melt(cor_matrix)

# Get feature order
feature_order <- colnames(cor_matrix)

# Set factor levels: reverse for Var1 (x-axis), keep normal for Var2 (y-axis)
cor_melted$Var1 <- factor(cor_melted$Var1, levels = rev(feature_order))  # x-axis
cor_melted$Var2 <- factor(cor_melted$Var2, levels = feature_order)       # y-axis

# Correlation Heatmap
heatmap_plot_ext <- ggplot(cor_melted, aes(Var1, Var2, fill = value)) +
  geom_tile() +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white",
                       midpoint = 0, limit = c(-1, 1)) +
  labs(fill = "Value") +
  xlab("") + ylab("") +
  ggtitle("Feature Correlation Heatmap") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1),
        plot.title = element_text(hjust = 0.5))

# -------------------------------------------------------------------------#
# Random Forest Importance Plot
# Train Random Forest Model
predictors_ext <- significant_df_ext[, !(names(significant_df_ext) %in% c("tumor_label"))]

set.seed(42)
rf_model_ext <- randomForest(x = predictors_ext,
                             y = feature_df_ext$tumor_label,
                             importance = TRUE, ntree = 500)

# Extract Feature Importance
importance_df_ext <- data.frame( Feature = rownames(importance(rf_model_ext)),
                                 MeanDecreaseGini = importance(rf_model_ext)[, "MeanDecreaseGini"] )

# Sort & Visualize
importance_df_ext <- importance_df_ext[order(-importance_df_ext$MeanDecreaseGini), ]

rf_plot_ext <- ggplot(importance_df_ext, aes(x = reorder(Feature, MeanDecreaseGini), y = MeanDecreaseGini)) +
  geom_bar(stat = "identity", fill = "lightgreen", width = 0.6) +
  geom_text(aes(label = round(MeanDecreaseGini, 2)), size = 2, family = "Times") +
  coord_flip() +
  xlab("Feature") + ylab("Importance (Gini)") +
  ggtitle("Random Forest Feature Importance") +
  theme(plot.title = element_text(hjust = 0.5))

# -------------------------------------------------------------------------#

print(feature_plot_ext)
print(heatmap_plot_ext)
print(rf_plot_ext)

ggsave("D:/CPE407/THESIS/Result Bi/feature_plot_ext_ieee.png",
       plot = feature_plot_ext,
       dpi = 300, width = 6, height = 4, units = "in", bg = "white")

ggsave("D:/CPE407/THESIS/Result Bi/heatmap_plot_ext_ieee.png",
       plot = heatmap_plot_ext,
       dpi = 300, width = 6, height = 4, units = "in", bg = "white")

ggsave("D:/CPE407/THESIS/Result Bi/rf_plot_ext_ieee.png",
       plot = rf_plot_ext,
       dpi = 300, width = 6, height = 4, units = "in", bg = "white")
