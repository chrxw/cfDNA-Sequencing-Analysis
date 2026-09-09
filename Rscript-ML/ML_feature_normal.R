# Load required library
library(stats)
library(ggplot2)
library(reshape2)
library(corrplot)
library(gridExtra)
library(GGally)
library(randomForest)
library(xgboost)

# Separate column by class
numeric_df <- dataframe[, (sapply(dataframe, class)) %in% c("numeric", "integer")]
numeric_df$tumor_label <- dataframe$tumor_label
character_df <- dataframe[, (sapply(dataframe, class)) == "character"]
character_df <- character_df[, !names(character_df) %in% c("tumor_type")]

feature_df <- cbind(numeric_df, character_df)

# Prepare Data
feature_df$tumor_label <- as.factor(feature_df$tumor_label)

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

# Get the names of significant features
significant_feature_names <- significant_pvalues_df$feature

# Create a new dataframe with only the significant features and the target variable
significant_df <- dataframe[, c("tumor_label", significant_feature_names)]

# -------------------------------------------------------------------------#

create_feature_importance_plot <- function(significant_pvalues_df) {
  significant_pvalues_df$importance <- -log10(significant_pvalues_df$p_value)
  
  plot <- ggplot(significant_pvalues_df, aes(x = reorder(feature, importance), y = importance)) +
    geom_bar(stat = "identity", fill = "lightpink", width = 0.6) +
    geom_text(aes(label = round(importance, 2)), size = 3) +
    coord_flip() +
    xlab("Feature") +
    ylab("-log10(p-value)") +
    ggtitle("Statistical Significance on -log10(p-value)") +
    theme_minimal()
}

feature_plot <- create_feature_importance_plot(significant_pvalues_df)

# -------------------------------------------------------------------------#

### Correlation Heatmap (for numeric features)
# Compute correlation matrix
numeric_features <- numeric_df[, names(numeric_df) %in% significant_feature_names]
cor_matrix <- cor(numeric_features, use = "pairwise.complete.obs")

# Melt correlation matrix for ggplot2
cor_melted <- reshape2::melt(cor_matrix)

# Get feature order
feature_order <- colnames(cor_matrix)

# Set factor levels: reverse for Var1 (x-axis), keep normal for Var2 (y-axis)
cor_melted$Var1 <- factor(cor_melted$Var1, levels = rev(feature_order))  # x-axis
cor_melted$Var2 <- factor(cor_melted$Var2, levels = feature_order)       # y-axis

# Plot heatmap
heatmap_plot <- ggplot(cor_melted, aes(Var1, Var2, fill = value)) +
  geom_tile() +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                       midpoint = 0, limit = c(-1, 1), space = "Lab") +
  theme_minimal() +
  xlab("") + ylab("") +
  ggtitle("Feature Correlation Heatmap") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1))

# -------------------------------------------------------------------------#

# Train Random Forest Model
predictors <- significant_df[, !(names(significant_df) %in% c("tumor_label"))]

set.seed(42)
rf_model <- randomForest(x = predictors, y = feature_df$tumor_label, importance = TRUE, ntree = 500)

# Extract Feature Importance
importance_df <- data.frame(
  Feature = rownames(importance(rf_model)),
  MeanDecreaseGini = importance(rf_model)[, "MeanDecreaseGini"]
)

# Sort & Visualize
importance_df <- importance_df[order(-importance_df$MeanDecreaseGini), ]

rf_plot <- ggplot(importance_df, aes(x = reorder(Feature, MeanDecreaseGini), y = MeanDecreaseGini)) +
  geom_bar(stat = "identity", fill = "lightgreen", width = 0.6) +
  geom_text(aes(label = round(MeanDecreaseGini, 2)), size = 2.5) +
  coord_flip() +
  xlab("Feature") + ylab("Importance (Gini)") +
  ggtitle("Random Forest Feature Importance") +
  theme_minimal()

# -------------------------------------------------------------------------#

### Pairwise Scatter Plot (for numeric features)
pairwise_plot <- ggpairs(numeric_features, aes(color = dataframe$tumor_label), 
                         lower = list(continuous = wrap("points", alpha = 0.5)))

# -------------------------------------------------------------------------#

### Display All Plots
grid.arrange(feature_plot)
grid.arrange(heatmap_plot)
grid.arrange(rf_plot)

# ----------------------------------IEEE ACCESS FORMAT---------------------------------------#

library(extrafont)
font_import()
loadfonts(device = "win")  # or "pdf" for non-Windows

# Set base font and size for all plots
theme_set(theme_minimal(base_family = "Times New Roman", base_size = 9))

# -------------------------------------------------------------------------#
# Feature Importance Plot
create_feature_importance_plot <- function(significant_pvalues_df) {
  significant_pvalues_df$importance <- -log10(significant_pvalues_df$p_value)
  
  plot <- ggplot(significant_pvalues_df, aes(x = reorder(feature, importance), y = importance)) +
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

feature_plot <- create_feature_importance_plot(significant_pvalues_df)

ggsave("D:/CPE407/THESIS/Result Normal/feature_plot_normal_ieee.png", plot = feature_plot,
       dpi = 300, width = 6, height = 4, units = "in", bg = "white")

grid.arrange(feature_plot)

# -------------------------------------------------------------------------#
# Correlation Heatmap
heatmap_plot <- ggplot(cor_melted, aes(Var1, Var2, fill = value)) +
  geom_tile() +
  scale_fill_gradient2(low = "blue", high = "red", mid = "white", 
                       midpoint = 0, limit = c(-1, 1), space = "Lab") +
  labs(fill = "Value") +
  theme_minimal(base_family = "Times New Roman", base_size = 9) +
  xlab("") + ylab("") +
  ggtitle("Feature Correlation Heatmap") +
  theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
  theme(plot.title = element_text(hjust = 0.5))

ggsave("D:/CPE407/THESIS/Result Normal/heatmap_plot_normal_ieee.png", plot = heatmap_plot,
       dpi = 300, width = 6, height = 4, units = "in", bg = "white")

grid.arrange(heatmap_plot)

# -------------------------------------------------------------------------#
# Random Forest Importance Plot
rf_plot <- ggplot(importance_df, aes(x = reorder(Feature, MeanDecreaseGini), y = MeanDecreaseGini)) +
  geom_bar(stat = "identity", fill = "lightgreen", width = 0.6) +
  geom_text(aes(label = round(MeanDecreaseGini, 2)), size = 2, family = "Times New Roman") +
  coord_flip() +
  xlab("Feature") + ylab("Importance (Gini)") +
  ggtitle("Random Forest Feature Importance") +
  theme_minimal(base_family = "Times New Roman", base_size = 9) +
  theme(plot.title = element_text(hjust = 0.5))

ggsave("D:/CPE407/THESIS/Result Normal/rf_plot_normal_ieee.png", plot = rf_plot,
       dpi = 300, width = 6, height = 4, units = "in", bg = "white")

grid.arrange(rf_plot)

# -------------------------------------------------------------------------#

# ----------------------------------BMC BIOINFORMATICS FORMAT----------------------------------#

library(ggplot2)
library(gridExtra)

# -------------------------------------------------------------------------#
# Font Setting (Stable Times New Roman for Windows)

windowsFonts(
  Times = windowsFont("Times New Roman")
)

# -------------------------------------------------------------------------#
# Global Theme

theme_set(
  theme_minimal(
    base_family = "Times",
    base_size = 9
  )
)

# -------------------------------------------------------------------------#
# BMC Figure Settings
# Full-width figure:
# 170 mm ≈ 6.7 inches
# 300 dpi

fig_width  <- 6.7
fig_height <- 4.5
fig_dpi    <- 300

# -------------------------------------------------------------------------#
# FEATURE IMPORTANCE PLOT

create_feature_importance_plot <- function(significant_pvalues_df) {
  
  significant_pvalues_df$importance <-
    -log10(significant_pvalues_df$p_value)
  
  plot <- ggplot(
    significant_pvalues_df,
    aes(
      x = reorder(feature, importance),
      y = importance
    )
  ) +
    
    geom_bar(
      stat = "identity",
      fill = "lightpink",
      width = 0.65
    ) +
    
    geom_text(
      aes(label = round(importance, 2)),
      size = 2.2,
      family = "Times",
      hjust = -0.1
    ) +
    
    coord_flip() +
    
    labs(
      x = "Feature",
      y = expression(-log[10] * "(p-value)")
    ) +
    
    theme_minimal(
      base_family = "Times",
      base_size = 9
    ) +
    
    theme(
      
      # BMC:
      # figure title should NOT be inside image
      plot.title = element_blank(),
      
      panel.grid.minor = element_blank(),
      
      panel.grid.major.y = element_blank(),
      
      axis.text = element_text(
        color = "black"
      ),
      
      axis.title = element_text(
        color = "black"
      ),
      
      panel.background = element_rect(
        fill = "white",
        color = NA
      ),
      
      plot.background = element_rect(
        fill = "white",
        color = NA
      )
    )
  
  return(plot)
}

feature_plot <- create_feature_importance_plot(
  significant_pvalues_df
)

# PNG
ggsave(
  "D:/CPE407/THESIS/Result Normal/feature_plot_normal_bmc.png",
  plot = feature_plot,
  dpi = fig_dpi,
  width = fig_width,
  height = fig_height,
  units = "in",
  bg = "white"
)

# PDF
ggsave(
  "D:/CPE407/THESIS/Result Normal/feature_plot_normal_bmc.pdf",
  plot = feature_plot,
  width = fig_width,
  height = fig_height,
  units = "in",
  bg = "white"
)

# -------------------------------------------------------------------------#
# CORRELATION HEATMAP

heatmap_plot <- ggplot(
  cor_melted,
  aes(
    Var1,
    Var2,
    fill = value
  )
) +
  
  geom_tile() +
  
  scale_fill_gradient2(
    low = "blue",
    mid = "white",
    high = "red",
    midpoint = 0,
    limit = c(-1, 1),
    name = "Correlation"
  ) +
  
  labs(
    x = "",
    y = ""
  ) +
  
  theme_minimal(
    base_family = "Times",
    base_size = 9
  ) +
  
  theme(
    
    # BMC:
    # no figure title inside image
    plot.title = element_blank(),
    
    axis.text.x = element_text(
      angle = 45,
      hjust = 1,
      color = "black"
    ),
    
    axis.text.y = element_text(
      color = "black"
    ),
    
    axis.title = element_text(
      color = "black"
    ),
    
    panel.grid = element_blank(),
    
    panel.background = element_rect(
      fill = "white",
      color = NA
    ),
    
    plot.background = element_rect(
      fill = "white",
      color = NA
    ),
    
    legend.title = element_text(
      size = 8,
      family = "Times"
    ),
    
    legend.text = element_text(
      size = 8,
      family = "Times"
    )
  )

# PNG
ggsave(
  "D:/CPE407/THESIS/Result Normal/heatmap_plot_normal_bmc.png",
  plot = heatmap_plot,
  dpi = fig_dpi,
  width = fig_width,
  height = fig_height,
  units = "in",
  bg = "white"
)

# PDF
ggsave(
  "D:/CPE407/THESIS/Result Normal/heatmap_plot_normal_bmc.pdf",
  plot = heatmap_plot,
  width = fig_width,
  height = fig_height,
  units = "in",
  bg = "white"
)

# -------------------------------------------------------------------------#
# RANDOM FOREST FEATURE IMPORTANCE

rf_plot <- ggplot(
  importance_df,
  aes(
    x = reorder(Feature, MeanDecreaseGini),
    y = MeanDecreaseGini
  )
) +
  
  geom_bar(
    stat = "identity",
    fill = "lightgreen",
    width = 0.65
  ) +
  
  geom_text(
    aes(label = round(MeanDecreaseGini, 2)),
    size = 2.2,
    family = "Times",
    hjust = -0.1
  ) +
  
  coord_flip() +
  
  labs(
    x = "Feature",
    y = "Importance (Gini)"
  ) +
  
  theme_minimal(
    base_family = "Times",
    base_size = 9
  ) +
  
  theme(
    
    # BMC:
    # remove figure title
    plot.title = element_blank(),
    
    panel.grid.minor = element_blank(),
    
    panel.grid.major.y = element_blank(),
    
    axis.text = element_text(
      color = "black"
    ),
    
    axis.title = element_text(
      color = "black"
    ),
    
    panel.background = element_rect(
      fill = "white",
      color = NA
    ),
    
    plot.background = element_rect(
      fill = "white",
      color = NA
    )
  )

# PNG
ggsave(
  "D:/CPE407/THESIS/Result Normal/rf_plot_normal_bmc.png",
  plot = rf_plot,
  dpi = fig_dpi,
  width = fig_width,
  height = fig_height,
  units = "in",
  bg = "white"
)

# PDF
ggsave(
  "D:/CPE407/THESIS/Result Normal/rf_plot_normal_bmc.pdf",
  plot = rf_plot,
  width = fig_width,
  height = fig_height,
  units = "in",
  bg = "white"
)