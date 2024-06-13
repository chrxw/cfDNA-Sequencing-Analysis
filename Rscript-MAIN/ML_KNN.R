# Load required library
library(class)
library(caret) # For confusionMatrix
library(ggplot2) # For Charts
library(pROC) # For AUC
library(kernlab)

# -------------------------------------------------------------------------#

# Define the training control for cross-validation
trainControl <- trainControl(method = "repeatedcv", number = 10, repeats = 3, 
                             verboseIter = FALSE, classProbs = TRUE)
metric_knn <- "Accuracy"

# Optimization
preProc <- c("center", "scale")

# -------------------------------------------------------------------------#

# Train the normal SVM model using training set
train_k <- 5
tune_grid_train_knn <- data.frame(k = train_k)

knn_model <- train(tumor_label ~ ., data = training_set, 
                   method = "knn", 
                   tuneGrid = tune_grid_train_knn, 
                   trControl = trainControl, 
                   metric = metric_knn)

knn_predictions <- predict(knn_model, validation_set)
knn_cm <- confusionMatrix(knn_predictions, y_val)
print(knn_cm)

# Sensitivity, specificity, and F1 score for the KNN model
knn_metrics <- confusionMatrix(knn_predictions, y_val)
knn_sensitivity <- knn_metrics$byClass["Sensitivity"]
knn_specificity <- knn_metrics$byClass["Specificity"]
knn_f1_score <- knn_metrics$byClass["F1"]

# Calculate AUC for the KNN model
knn_roc <- roc(y_val, as.numeric(knn_predictions))
knn_auc <- knn_roc$auc

# Print the results
cat("KNN Model Metrics:\n",
    "Sensitivity:", knn_sensitivity, "\n",
    "Specificity:", knn_specificity, "\n",
    "F1 Score:", knn_f1_score, "\n",
    "AUC:", knn_auc, "\n")

# Plot ROC curve
plot.roc(knn_roc, col = "blue", main = "ROC Curve for KNN Model")

# -------------------------------------------------------------------------#

# KNN tuning by training set
tune_grid_tune_knn <- data.frame(
  k = seq(1, 100, by = 2)
)

knn_tune_model <- train(tumor_label ~ ., data = training_set, 
                        method = "knn", 
                        tuneGrid = tune_grid_tune_knn, 
                        trControl = trainControl,
                        metric = metric_knn,
                        preProc = preProc)

# Get the best tuning parameters
best_tune_knn <- knn_tune_model$bestTune
print(best_tune_knn)

# Evaluation tuned model on the validation set
knn_tune_predictions <- predict(knn_tune_model, validation_set)
knn_tune_cm <- confusionMatrix(knn_tune_predictions, y_val)
print(knn_tune_cm)

# -------------------------------------------------------------------------#

# Model Testing
knn_test_predictions <- predict(knn_tune_model, testing_set)
knn_test_cm <- confusionMatrix(knn_test_predictions, y_test)
print(knn_test_cm)

# -------------------------------------------------------------------------#

# Sensitivity, specificity, and F1 score for the tuned KNN model
knn_tuned_metrics <- confusionMatrix(knn_test_predictions, y_test)
knn_tuned_sensitivity <- knn_tuned_metrics$byClass["Sensitivity"]
knn_tuned_specificity <- knn_tuned_metrics$byClass["Specificity"]
knn_tuned_f1_score <- knn_tuned_metrics$byClass["F1"]

# Calculate AUC for the tuned KNN model
knn_tuned_roc <- roc(y_test, as.numeric(knn_test_predictions))
knn_tuned_auc <- knn_tuned_roc$auc

# Print the results
cat("Tuned KNN Model Metrics:\n",
    "Sensitivity:", knn_tuned_sensitivity, "\n",
    "Specificity:", knn_tuned_specificity, "\n",
    "F1 Score:", knn_tuned_f1_score, "\n",
    "AUC:", knn_tuned_auc, "\n")

# Result as dataframe
knn_tuned_metrics_df <- data.frame(
  Metric = c("Sensitivity", "Specificity", "F1 Score", "AUC"),
  Value = c(knn_tuned_sensitivity, knn_tuned_specificity, knn_tuned_f1_score, knn_tuned_auc)
)
knn_tuned_metrics_df$Model <- "KNN"

# Plot ROC curve
plot.roc(knn_tuned_roc, col = "blue", main = "ROC Curve for Tuned KNN Model")

# -------------------------------------------------------------------------#

# Export result metrics
saveRDS(knn_tuned_metrics_df, "/omics/odcf/analysis/OE0290_projects/pediatric_tumor/whole_genome_sequencing_CRAsnakemake/HDS_project/MachineLearning/R_setting/knn_tuned_metrics_df.rds")

# Save the model
saveRDS(knn_model, "/omics/odcf/analysis/OE0290_projects/pediatric_tumor/whole_genome_sequencing_CRAsnakemake/HDS_project/MachineLearning/Model/knn_model.rds")
saveRDS(knn_tune_model, "/omics/odcf/analysis/OE0290_projects/pediatric_tumor/whole_genome_sequencing_CRAsnakemake/HDS_project/MachineLearning/Model/knn_tune_model.rds")
