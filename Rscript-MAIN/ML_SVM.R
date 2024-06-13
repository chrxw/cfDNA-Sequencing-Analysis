# Load necessary libraries
library(e1071) # For SVM
library(caret) # For confusionMatrix
library(ggplot2) # For Charts
library(pROC) # For AUC
library(kernlab)

# -------------------------------------------------------------------------#

# Define the training control for cross-validation
trainControl <- trainControl(method = "repeatedcv", number = 10, repeats = 3, 
                             verboseIter = FALSE, classProbs = TRUE)
metric_svm <- "Accuracy"

# Optimization
preProc <- c("center", "scale")

# -------------------------------------------------------------------------#

# Train the normal SVM model using training set
svm_model <- train(tumor_label ~ ., data = training_set, 
                   method = "svmRadial", 
                   trControl = trainControl,
                   metric = metric_svm)

# Evaluation on the validation set
svm_predictions <- predict(svm_model, validation_set)
svm_cm <- confusionMatrix(svm_predictions, y_val)
print(svm_cm)

# Sensitivity, specificity, and F1 score for the SVM model
svm_metrics <- confusionMatrix(svm_predictions, y_val)
svm_sensitivity <- svm_metrics$byClass["Sensitivity"]
svm_specificity <- svm_metrics$byClass["Specificity"]
svm_f1_score <- svm_metrics$byClass["F1"]

# Calculate AUC for the SVM model
svm_roc <- roc(y_val, as.numeric(svm_predictions))
svm_auc <- svm_roc$auc

# Print the results
cat("SVM Model Metrics:\n",
    "Sensitivity:", svm_sensitivity, "\n",
    "Specificity:", svm_specificity, "\n",
    "F1 Score:", svm_f1_score, "\n",
    "AUC:", svm_auc, "\n")

# Plot ROC curve
plot.roc(svm_roc, col = "blue", main = "ROC Curve for SVM Model")

# -------------------------------------------------------------------------#

# SVM tuning by training set
tune_grid_tune_svm <- expand.grid(
  C = seq(0.1, 1, by = 0.1),
  sigma = seq(0, 1, by = 0.1)
)

svm_tune_model <- train(tumor_label ~ ., data = training_set, 
                        method = "svmRadial", 
                        tuneGrid = tune_grid_tune_svm, 
                        trControl = trainControl,
                        metric = metric_svm,
                        preProc = preProc)

# Get the best tuning parameters
best_tune_svm <- svm_tune_model$bestTune
print(best_tune_svm)

# Evaluation tuned model on the validation set
svm_tune_predictions <- predict(svm_tune_model, validation_set)
svm_tune_cm <- confusionMatrix(svm_tune_predictions, y_val)
print(svm_tune_cm)

# -------------------------------------------------------------------------#

# Model Testing
svm_test_predictions <- predict(svm_tune_model, testing_set)
svm_test_cm <- confusionMatrix(svm_test_predictions, y_test)
print(svm_test_cm)

# -------------------------------------------------------------------------#

# Sensitivity, specificity, and F1 score for the tuned SVM model
svm_tuned_metrics <- confusionMatrix(svm_test_predictions, y_test)
svm_tuned_sensitivity <- svm_tuned_metrics$byClass["Sensitivity"]
svm_tuned_specificity <- svm_tuned_metrics$byClass["Specificity"]
svm_tuned_f1_score <- svm_tuned_metrics$byClass["F1"]

# Calculate AUC for the tuned SVM model
svm_tuned_roc <- roc(y_test, as.numeric(svm_test_predictions))
svm_tuned_auc <- svm_tuned_roc$auc

# Print the results
cat("Tuned SVM Model Metrics:\n",
    "Sensitivity:", svm_tuned_sensitivity, "\n",
    "Specificity:", svm_tuned_specificity, "\n",
    "F1 Score:", svm_tuned_f1_score, "\n",
    "AUC:", svm_tuned_auc, "\n")

# Result as dataframe
svm_tuned_metrics_df <- data.frame(
  Metric = c("Sensitivity", "Specificity", "F1 Score", "AUC"),
  Value = c(svm_tuned_sensitivity, svm_tuned_specificity, svm_tuned_f1_score, svm_tuned_auc)
)
svm_tuned_metrics_df$Model <- "SVM"

# Plot ROC curve
plot.roc(svm_tuned_roc, col = "blue", main = "ROC Curve for Tuned SVM Model")

# -------------------------------------------------------------------------#

# Export result metrics
saveRDS(svm_tuned_metrics_df, "/omics/odcf/analysis/OE0290_projects/pediatric_tumor/whole_genome_sequencing_CRAsnakemake/HDS_project/MachineLearning/R_setting/svm_tuned_metrics_df.rds")

# Save the model
saveRDS(svm_model, "/omics/odcf/analysis/OE0290_projects/pediatric_tumor/whole_genome_sequencing_CRAsnakemake/HDS_project/MachineLearning/Model/svm_model.rds")
saveRDS(svm_tune_model, "/omics/odcf/analysis/OE0290_projects/pediatric_tumor/whole_genome_sequencing_CRAsnakemake/HDS_project/MachineLearning/Model/svm_tune_model.rds")
