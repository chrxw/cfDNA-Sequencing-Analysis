# Load required libraries
library(xgboost)
library(caret)    # For confusionMatrix and train functions
library(ggplot2)  # For charts
library(pROC)     # For AUC
library(kernlab)  # For SVM

# -------------------------------------------------------------------------#

# Define train control with 10-fold cross validation and 3 repeats
trainControl <- trainControl(method = "repeatedcv", number = 10, repeats = 3, 
                             verboseIter = TRUE, classProbs = TRUE)

metric_xgb <- "Accuracy"

# Optimization
preProc <- c("center", "scale")

# -------------------------------------------------------------------------#

# Train the normal SVM model using training set
xgb_model <- train(tumor_label ~ ., data = training_set, method = "xgbTree", 
                   metric = metric_xgb, trControl = trainControl)

# Generate confusion matrix
xgb_predictions <- predict(xgb_model, validation_set)
xgb_cm <- confusionMatrix(xgb_predictions, y_val)
print(xgb_cm)

# Sensitivity, specificity, and F1 score for the XGBoost model
xgb_metrics <- confusionMatrix(xgb_predictions, y_val)
xgb_sensitivity <- xgb_metrics$byClass["Sensitivity"]
xgb_specificity <- xgb_metrics$byClass["Specificity"]
xgb_f1_score <- xgb_metrics$byClass["F1"]

# Calculate AUC for the XGBoost model
xgb_roc <- roc(y_val, as.numeric(xgb_predictions))
xgb_auc <- xgb_roc$auc

# Print the results
cat("XGBoost Model Metrics:\n",
    "Sensitivity:", xgb_sensitivity, "\n",
    "Specificity:", xgb_specificity, "\n",
    "F1 Score:", xgb_f1_score, "\n",
    "AUC:", xgb_auc, "\n")

# Plot ROC curve
plot.roc(xgb_roc, col = "blue", main = "ROC Curve for XGBoost Model")

# -------------------------------------------------------------------------#

# XGBoost tuning by training set
tune_grid_tune_xgb <- expand.grid(
  nrounds = c(50, 100, 150),
  max_depth = c(3, 5, 7),
  eta = c(0.01, 0.1, 0.3),
  gamma = c(0, 0.1, 0.2),
  colsample_bytree = c(0.7, 0.8, 1),
  min_child_weight = c(1, 3, 5),
  subsample = c(0.7, 0.8, 1)
)

xgb_tune_model <- train(tumor_label ~ ., data = training_set, 
                        method = "xgbTree", 
                        tuneGrid = tune_grid_tune_xgb, 
                        trControl = trainControl,
                        metric = metric_xgb,
                        preProc = preProc)

# Get the best tuning parameters
best_tune_xgb <- xgb_tune_model$bestTune
print(best_tune_xgb)

# Evaluation tuned model on the validation set
xgb_tune_predictions <- predict(xgb_tune_model, validation_set)
xgb_tune_cm <- confusionMatrix(xgb_tune_predictions, y_val)
print(xgb_tune_cm)

# -------------------------------------------------------------------------#

# Model Testing
xgb_test_predictions <- predict(xgb_tune_model, testing_set)
xgb_test_cm <- confusionMatrix(xgb_test_predictions, y_test)
print(xgb_test_cm)

# -------------------------------------------------------------------------#

# Sensitivity, specificity, and F1 score for the tuned XGBoost model
xgb_tuned_metrics <- confusionMatrix(xgb_test_predictions, y_test)
xgb_tuned_sensitivity <- xgb_tuned_metrics$byClass["Sensitivity"]
xgb_tuned_specificity <- xgb_tuned_metrics$byClass["Specificity"]
xgb_tuned_f1_score <- xgb_tuned_metrics$byClass["F1"]

# Calculate AUC for the tuned XGBoost model
xgb_tuned_roc <- roc(y_test, as.numeric(xgb_test_predictions))
xgb_tuned_auc <- xgb_tuned_roc$auc

# Print the results
cat("Tuned XGBoost Model Metrics:\n",
    "Sensitivity:", xgb_tuned_sensitivity, "\n",
    "Specificity:", xgb_tuned_specificity, "\n",
    "F1 Score:", xgb_tuned_f1_score, "\n",
    "AUC:", xgb_tuned_auc, "\n")

# Result as dataframe
xgb_tuned_metrics_df <- data.frame(
  Metric = c("Sensitivity", "Specificity", "F1 Score", "AUC"),
  Value = c(xgb_tuned_sensitivity, xgb_tuned_specificity, xgb_tuned_f1_score, xgb_tuned_auc)
)
xgb_tuned_metrics_df$Model <- "XGBoost"

# Plot ROC curve
plot.roc(xgb_tuned_roc, col = "blue", main = "ROC Curve for Tuned XGBoost Model")

# -------------------------------------------------------------------------#

# Export result metrics
saveRDS(xgb_tuned_metrics_df, "path/to/your/xgb_tuned_metrics_df.rds")

# Save the models
saveRDS(xgb_model, "path/to/your/xgb_model.rds")
saveRDS(xgb_tune_model, "path/to/your/xgb_tune_model.rds")
