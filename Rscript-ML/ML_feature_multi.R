# Load required library
library(stats)
library(ggplot2)
library(reshape2)
library(corrplot)
library(gridExtra)
library(GGally)
library(randomForest)

# Separate column by class
numeric_df_multi <- dataframe[, sapply(dataframe, is.numeric)]
numeric_df_multi$tumor_type <- as.factor(dataframe$tumor_type)  # Keep as factor

character_df_multi <- dataframe[, sapply(dataframe, is.character) & !(names(dataframe) %in% c("tumor_label"))]
character_df_multi[] <- lapply(character_df_multi, as.factor)  # Convert to factors

feature_df_multi <- cbind(numeric_df_multi, character_df_multi)

# -------------------------------------------------------------------------#

## ANOVA
## Initialize a list to store p-values for numerical features using ANOVA
numeric_pvalues <- list()

# Perform ANOVA for each numerical feature against the target variable
for (col in names(numeric_df_multi)[!names(numeric_df_multi) %in% c("tumor_label", "tumor_type")]) {
  anova_result <- aov(numeric_df_multi[[col]] ~ tumor_type, data = numeric_df_multi)
  numeric_pvalues[[col]] <- summary(anova_result)[[1]][["Pr(>F)"]][1]  # Extract p-value
}

# Remove NA values from numeric p-values
numeric_pvalues <- numeric_pvalues[!is.na(numeric_pvalues)]

# Print the numeric p-values
print(numeric_pvalues)

# -------------------------------------------------------------------------#

### Fisher's Exact Test
# Initialize a list to store p-values for categorical features
categorical_pvalues <- list()

for (col in setdiff(names(character_df_multi), "tumor_type")) {
  contingency_table <- table(character_df_multi[[col]], character_df_multi$tumor_type)
  
  if (length(unique(character_df_multi[[col]])) < 50) {
    test_result <- fisher.test(contingency_table, simulate.p.value = TRUE, B = 10000)
  } else {
    test_result <- chisq.test(contingency_table)
  }
  
  categorical_pvalues[[col]] <- test_result$p.value
}

categorical_pvalues <- categorical_pvalues[!is.na(categorical_pvalues)]
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
significant_pvalues_df_multi <- pvalues_df[pvalues_df$p_value < 0.05, ]

# -------------------------------------------------------------------------#

# Get the names of significant features
significant_feature_names <- significant_pvalues_df_multi$feature

# Create a new dataframe with only the significant features and the target variable
significant_df_multi <- dataframe[, c("tumor_type", significant_feature_names)]

# -------------------------------------------------------------------------#

create_feature_importance_plot <- function(significant_pvalues_df_multi) {
  significant_pvalues_df_multi$importance <- -log10(significant_pvalues_df_multi$p_value)
  
  plot <- ggplot(significant_pvalues_df_multi, aes(x = reorder(feature, importance), y = importance)) +
    geom_bar(stat = "identity", fill = "lightpink", width = 0.6) +
    geom_text(aes(label = round(importance, 2)), size = 3) +
    coord_flip() +
    xlab("Feature") +
    ylab("-log10(p-value)") +
    ggtitle("Statistical Significance on -log10(p-value)") +
    theme_minimal()
}

feature_plot_multi <- create_feature_importance_plot(significant_pvalues_df_multi)

# -------------------------------------------------------------------------#

### Correlation Heatmap (for numeric features)
# Compute correlation matrix
numeric_features_multi <- numeric_df_multi[, names(numeric_df_multi) %in% significant_feature_names]
cor_matrix <- cor(numeric_features_multi, use = "pairwise.complete.obs")

# Melt correlation matrix for ggplot2
cor_melted <- reshape2::melt(cor_matrix)

# Get feature order
feature_order <- colnames(cor_matrix)

# Set factor levels: reverse for Var1 (x-axis), keep normal for Var2 (y-axis)
cor_melted$Var1 <- factor(cor_melted$Var1, levels = rev(feature_order))  # x-axis
cor_melted$Var2 <- factor(cor_melted$Var2, levels = feature_order)       # y-axis

# Plot heatmap
heatmap_plot_multi <- ggplot(cor_melted, aes(Var1, Var2, fill = value)) +
  geom_tile() +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                       midpoint = 0, limit = c(-1, 1), space = "Lab") +
  theme_minimal() +
  xlab("") + ylab("") +
  ggtitle("Feature Correlation Heatmap") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# -------------------------------------------------------------------------#

# Train Random Forest Model
predictors_multi <- significant_df_multi[, !(names(significant_df_multi) %in% c("tumor_type"))]

set.seed(42)
rf_model_multi <- randomForest(x = predictors_multi, y = feature_df_multi$tumor_type, importance = TRUE, ntree = 500)

# multiract Feature Importance
importance_df_multi <- data.frame(
  Feature = rownames(importance(rf_model_multi)),
  MeanDecreaseGini = importance(rf_model_multi)[, "MeanDecreaseGini"]
)

# Sort & Visualize
importance_df_multi <- importance_df_multi[order(-importance_df_multi$MeanDecreaseGini), ]

rf_plot_multi <- ggplot(importance_df_multi, aes(x = reorder(Feature, MeanDecreaseGini), y = MeanDecreaseGini)) +
  geom_bar(stat = "identity", fill = "lightgreen", width = 0.6) +
  geom_text(aes(label = round(MeanDecreaseGini, 2)), size = 2.5) +
  coord_flip() +
  xlab("Feature") + ylab("Importance (Gini)") +
  ggtitle("Random Forest Feature Importance (Multiclass)") +
  theme_minimal()

# -------------------------------------------------------------------------#

### Pairwise Scatter Plot (for numeric features)
pairwise_plot_multi <- ggpairs(numeric_features_multi, aes(color = dataframe$tumor_type), 
                             lower = list(continuous = wrap("points", alpha = 0.5)))

# -------------------------------------------------------------------------#

### Display All Plots
grid.arrange(feature_plot_multi)
grid.arrange(heatmap_plot_multi)
grid.arrange(rf_plot_multi)

# ----------------------------------IEEE ACCESS FORMAT---------------------------------------#

library(extrafont)
font_import()
loadfonts(device = "win")  # or "pdf" for non-Windows

# Set base font and size for all plots
theme_set(theme_minimal(base_family = "Times New Roman", base_size = 9))

# -------------------------------------------------------------------------#
# Feature Importance Plot
create_feature_importance_plot <- function(significant_pvalues_df_multi) {
  significant_pvalues_df_multi$importance <- -log10(significant_pvalues_df_multi$p_value)
  
  plot <- ggplot(significant_pvalues_df_multi, aes(x = reorder(feature, importance), y = importance)) +
    geom_bar(stat = "identity", fill = "lightpink", width = 0.6) +
    geom_text(aes(label = round(importance, 2)), size = 2, family = "Times New Roman") +
    coord_flip() +
    xlab("Feature") +
    ylab("-log10 (p-value)") +
    ggtitle("Statistical Significance on -log10 (p-value)") +
    theme_minimal(base_family = "Times New Roman", base_size = 9) +
    theme(plot.title = element_text(hjust = 0.5))
  
  return(plot)
}

feature_plot_multi <- create_feature_importance_plot(significant_pvalues_df_multi)

ggsave("D:/CPE407/THESIS/Result Multi/feature_plot_multi_ieee.png", plot = feature_plot_multi,
       dpi = 300, width = 6, height = 4, units = "in", bg = "white")

grid.arrange(feature_plot_multi)

# -------------------------------------------------------------------------#
# Correlation Heatmap
heatmap_plot_multi <- ggplot(cor_melted, aes(Var1, Var2, fill = value)) +
  geom_tile() +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                       midpoint = 0, limit = c(-1, 1), space = "Lab") +
  labs(fill = "Value") +
  theme_minimal(base_family = "Times New Roman", base_size = 9) +
  xlab("") + ylab("") +
  ggtitle("Feature Correlation Heatmap") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  theme(plot.title = element_text(hjust = 0.5))

ggsave("D:/CPE407/THESIS/Result Multi/heatmap_plot_multi_ieee.png", plot = heatmap_plot_multi,
       dpi = 300, width = 6, height = 4, units = "in", bg = "white")

grid.arrange(heatmap_plot_multi)

# -------------------------------------------------------------------------#
# Random Forest Importance Plot
rf_plot_multi <- ggplot(importance_df_multi, aes(x = reorder(Feature, MeanDecreaseGini), y = MeanDecreaseGini)) +
  geom_bar(stat = "identity", fill = "lightgreen", width = 0.6) +
  geom_text(aes(label = round(MeanDecreaseGini, 2)), size = 2, family = "Times New Roman") +
  coord_flip() +
  xlab("Feature") + ylab("Importance (Gini)") +
  ggtitle("Random Forest Feature Importance") +
  theme_minimal(base_family = "Times New Roman", base_size = 9) +
  theme(plot.title = element_text(hjust = 0.5))

ggsave("D:/CPE407/THESIS/Result Multi/rf_plot_multi_ieee.png", plot = rf_plot_multi,
       dpi = 300, width = 6, height = 4, units = "in", bg = "white")

grid.arrange(rf_plot_multi)

# -------------------------------------------------------------------------#
