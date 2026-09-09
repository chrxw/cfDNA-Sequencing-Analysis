# Load required libraries
library(xgboost)  # For XGBoost
library(caret)    # For confusionMatrix and train functions
library(ggplot2)  # For charts
library(pROC)     # For AUC
library(kernlab)

train_xgb_model <- function(training_set, validation_set, testing_set, name) {
  
  # -------------------------------------------------------------------------#
  
  trainControl <- trainControl(method = "repeatedcv", number = 10, repeats = 3, 
                               verboseIter = FALSE, classProbs = TRUE, allowParallel = TRUE)
  metric_xgb <- "Accuracy"
  
  preProc <- c("center", "scale")
  
  # -------------------------------------------------------------------------#
  
  calculate_metrics <- function(cm) {
    sensitivity <- cm$byClass["Sensitivity"]
    precision <- cm$byClass["Pos Pred Value"]
    recall <- sensitivity
    
    if (is.na(precision) || is.na(recall) || (precision + recall) == 0) {
      f1 <- NA
    } else {
      f1 <- 2 * (precision * recall) / (precision + recall)
    }
    list(precision = precision, recall = recall, f1 = f1)
  }
  
  # -------------------------------------------------------------------------#
  
  # Train xgb model
  cat("Processing XGBoost for", name, "\n")
  
  # Train the normal XGBoost model using training set
  xgb_model <- train(tumor_label ~ . - tumor_type - row_id,
                     data = training_set,
                     method = "xgbTree", 
                     trControl = trainControl, 
                     metric = metric_xgb,
                     preProcess = preProc)
  
  # Predictions for training set
  y_pred_train_prob <- predict(xgb_model, training_set, type = "prob")[, "tumor"] # Probabilities
  y_pred_train_prob_full <- predict(xgb_model, training_set, type = "prob")
  y_pred_train_class <- predict(xgb_model, training_set, type = "raw")          # Hard predictions
  
  # Compute confusion matrix for training set
  xgb_cm_train <- confusionMatrix(y_pred_train_class, training_set$tumor_label)
  metrics_train <- calculate_metrics(xgb_cm_train)
  roc_train <- roc(training_set$tumor_label, y_pred_train_prob)
  auc_train <- roc_train$auc
  xgb_sensitivity <- xgb_cm_train$byClass["Sensitivity"]
  xgb_specificity <- xgb_cm_train$byClass["Specificity"]
  xgb_f1_score <- xgb_cm_train$byClass["F1"]
  
  # Plot ROC curve for training set
  plot.roc(roc_train, col = "blue", main = paste("ROC Curve for the XGBoost Model (Training Set):", name))
  
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
  
  xgb_tune_model <- train(tumor_label ~ . - tumor_type - row_id,
                          data = training_set,
                          method = "xgbTree", 
                          tuneGrid = tune_grid_tune_xgb, 
                          trControl = trainControl,
                          metric = metric_xgb,
                          preProcess = preProc)
  
  # Get the best tuning parameters
  best_tune_xgb <- xgb_tune_model$bestTune
  cat("Best tuning parameters:\n")
  print(best_tune_xgb)
  
  # Validation set predictions
  y_pred_val_prob <- predict(xgb_tune_model, validation_set, type = "prob")[, "tumor"]
  y_pred_val_prob_full <- predict(xgb_tune_model, validation_set, type = "prob")
  y_pred_val_class <- predict(xgb_tune_model, validation_set, type = "raw")
  
  xgb_cm_val <- confusionMatrix(y_pred_val_class, validation_set$tumor_label)
  metrics_val <- calculate_metrics(xgb_cm_val)
  roc_val <- roc(validation_set$tumor_label, y_pred_val_prob)
  auc_val <- roc_val$auc
  xgb_tune_sensitivity <- xgb_cm_val$byClass["Sensitivity"]
  xgb_tune_specificity <- xgb_cm_val$byClass["Specificity"]
  xgb_tune_f1_score <- xgb_cm_val$byClass["F1"]
  
  # Plot ROC curve for validation set
  plot.roc(roc_val, col = "green", main = paste("ROC Curve for the XGBoost Model (Validation Set):", name))
  
  # -------------------------------------------------------------------------#
  
  # Test set predictions
  y_pred_test_prob <- predict(xgb_tune_model, testing_set, type = "prob")[, "tumor"]
  y_pred_test_prob_full <- predict(xgb_tune_model, testing_set, type = "prob")
  y_pred_test_class <- predict(xgb_tune_model, testing_set, type = "raw")
  
  xgb_cm_test <- confusionMatrix(y_pred_test_class, testing_set$tumor_label)
  metrics_test <- calculate_metrics(xgb_cm_test)
  roc_test <- roc(testing_set$tumor_label, y_pred_test_prob)
  auc_test <- roc_test$auc
  xgb_test_sensitivity <- xgb_cm_test$byClass["Sensitivity"]
  xgb_test_specificity <- xgb_cm_test$byClass["Specificity"]
  xgb_test_f1_score <- xgb_cm_test$byClass["F1"]
  
  # Plot ROC curve for test set
  plot.roc(roc_test, col = "red", main = paste("ROC Curve for the XGBoost Model (Test Set):", name))
  
  # ----------------- SAVE BINARYCLASS ROC (Train + Val + Test) ----------------- #
  
  plot_combined_roc <- function(name, file_name) {
    
    size <- 1600
    scale <- size / 1600
    
    png(file_name, width = size, height = size, res = 300)
    
    par(family = "serif", mar = c(5, 5, 4, 2))
    
    plot(0, 0,
         type = "n",
         xlim = c(0, 1),
         ylim = c(0, 1),
         xlab = "False Positive Rate (1 - Specificity)",
         ylab = "True Positive Rate (Sensitivity)",
         main = paste("ROC Curves for XGBoost Model:", name),
         cex.main = 1.1 * scale,
         cex.lab = 1.1 * scale,
         cex.axis = 1.1 * scale)
    
    # Diagonal line
    abline(a = 0, b = 1, lty = 2, col = "gray")
    
    # ROC curves
    lines(1 - roc_train$specificities,roc_train$sensitivities,
          col = "blue", lwd = 2)
    
    lines(1 - roc_val$specificities,roc_val$sensitivities,
          col = "green3", lwd = 2)
    
    lines(1 - roc_test$specificities,roc_test$sensitivities,
          col = "red", lwd = 2)
    
    legend("bottomright",
           legend = c(
             paste("Training (AUC =", round(auc_train, 3), ")"),
             paste("Validation (AUC =", round(auc_val, 3), ")"),
             paste("Test (AUC =", round(auc_test, 3), ")")
           ),
           col = c("blue", "green", "red"),
           lwd = 2,
           cex = 1 * scale,
           bty = "o")
    
    dev.off()
  }
  
  plot_combined_roc(
    name,
    paste0("path/to/your/roc/graph", name, ".png")
  )
  
  # ----------------- Prepare a Results DataFrame ----------------- #
  
  xgb_metrics_df <- data.frame(
    Metric = c("Accuracy", "AUC", "Precision", "Recall", "F1 Score"),
    Train = c(xgb_cm_train$overall["Accuracy"], auc_train, metrics_train$precision, metrics_train$recall, metrics_train$f1),
    Validation = c(xgb_cm_val$overall["Accuracy"], auc_val, metrics_val$precision, metrics_val$recall, metrics_val$f1),
    Test = c(xgb_cm_test$overall["Accuracy"], auc_test, metrics_test$precision, metrics_test$recall, metrics_test$f1)
  )
  xgb_metrics_df$Model <- "XGBoost"
  
  return(list(
    xgb_model = xgb_model,
    xgb_tune_model = xgb_tune_model,
    best_tune = best_tune_xgb,
    confusion_matrices = list(train = xgb_cm_train, validation = xgb_cm_val, test = xgb_cm_test),
    roc_curves = list(train = roc_train, validation = roc_val, test = roc_test),
    aucs = list(train = auc_train, validation = auc_val, test = auc_test),
    metrics = list(train = metrics_train, validation = metrics_val, test = metrics_test),
    results = xgb_metrics_df,
    predictions = list(
      train = list(
        Row_id = training_set$row_id,
        pos_probabilities = y_pred_train_prob,
        probabilities = y_pred_train_prob_full,
        classes = y_pred_train_class,
        actual = training_set$tumor_label
      ),
      validation = list(
        Row_id = validation_set$row_id,
        pos_probabilities = y_pred_val_prob,
        probabilities = y_pred_val_prob_full,
        classes = y_pred_val_class,
        actual = validation_set$tumor_label
      ),
      test = list(
        Row_id = testing_set$row_id,
        pos_probabilities = y_pred_test_prob,
        probabilities = y_pred_test_prob_full,
        classes = y_pred_test_class,
        actual = testing_set$tumor_label
      )
    )
  ))
}