# Load necessary libraries
library(e1071) # For SVM
library(caret) # For confusionMatrix
library(ggplot2) # For Charts
library(pROC) # For AUC
library(kernlab)

train_svm_model <- function(training_set, validation_set, testing_set, name) {
  
  # -------------------------------------------------------------------------#
  
  trainControl <- trainControl(method = "repeatedcv", number = 10, repeats = 3, 
                               verboseIter = FALSE, classProbs = TRUE, allowParallel = TRUE)
  metric_svm <- "Accuracy"
  
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
  
  # Train svm model
  cat("Processing SVM for", name, "\n")
  
  # Train the normal SVM model using training set
  svm_model <- train(tumor_label ~ . - tumor_type - row_id,
                     data = training_set,
                     method = "svmRadial", 
                     trControl = trainControl,
                     metric = metric_svm,
                     preProcess = preProc)
  
  # Predictions for training set
  y_pred_train_prob <- predict(svm_model, training_set, type = "prob")[, "tumor"] # Probabilities
  y_pred_train_prob_full <- predict(svm_model, training_set, type = "prob")
  y_pred_train_class <- predict(svm_model, training_set, type = "raw")          # Hard predictions
  
  # Compute confusion matrix for training set
  svm_cm_train <- confusionMatrix(y_pred_train_class, training_set$tumor_label)
  metrics_train <- calculate_metrics(svm_cm_train)
  roc_train <- roc(training_set$tumor_label, y_pred_train_prob)
  auc_train <- roc_train$auc
  svm_sensitivity <- svm_cm_train$byClass["Sensitivity"]
  svm_specificity <- svm_cm_train$byClass["Specificity"]
  svm_f1_score <- svm_cm_train$byClass["F1"]
  
  # Plot ROC curve for training set
  plot.roc(roc_train, col = "blue", main = paste("ROC Curve for the SVM Model (Training Set):", name))
  
  # -------------------------------------------------------------------------#
  
  # Hyperparameter tuning
  tune_grid_tune_svm <- expand.grid(
    C = seq(0.1, 5, by = 0.1),
    sigma = seq(0.1, 5, by = 0.1)
  )

  svm_tune_model <- train(tumor_label ~ . - tumor_type - row_id,
                          data = training_set,
                          method = "svmRadial", 
                          tuneGrid = tune_grid_tune_svm, 
                          trControl = trainControl,
                          metric = metric_svm,
                          preProcess = preProc)
  
  # Get the best tuning parameters
  best_tune_svm <- svm_tune_model$bestTune
  cat("Best tuning parameters:\n")
  print(best_tune_svm)
  
  # Validation set predictions
  y_pred_val_prob <- predict(svm_tune_model, validation_set, type = "prob")[, "tumor"]
  y_pred_val_prob_full <- predict(svm_tune_model, validation_set, type = "prob")
  y_pred_val_class <- predict(svm_tune_model, validation_set, type = "raw")
  
  svm_cm_val <- confusionMatrix(y_pred_val_class, validation_set$tumor_label)
  metrics_val <- calculate_metrics(svm_cm_val)
  roc_val <- roc(validation_set$tumor_label, y_pred_val_prob)
  auc_val <- roc_val$auc
  svm_tune_sensitivity <- svm_cm_val$byClass["Sensitivity"]
  svm_tune_specificity <- svm_cm_val$byClass["Specificity"]
  svm_tune_f1_score <- svm_cm_val$byClass["F1"]
  
  # Plot ROC curve for validation set
  plot.roc(roc_val, col = "green", main = paste("ROC Curve for the SVM Model (Validation Set):", name))
  
  # -------------------------------------------------------------------------#
  
  # Test set predictions
  y_pred_test_prob <- predict(svm_tune_model, testing_set, type = "prob")[, "tumor"]
  y_pred_test_prob_full <- predict(svm_tune_model, testing_set, type = "prob")
  y_pred_test_class <- predict(svm_tune_model, testing_set, type = "raw")
  
  svm_cm_test <- confusionMatrix(y_pred_test_class, testing_set$tumor_label)
  metrics_test <- calculate_metrics(svm_cm_test)
  roc_test <- roc(testing_set$tumor_label, y_pred_test_prob)
  auc_test <- roc_test$auc
  svm_test_sensitivity <- svm_cm_test$byClass["Sensitivity"]
  svm_test_specificity <- svm_cm_test$byClass["Specificity"]
  svm_test_f1_score <- svm_cm_test$byClass["F1"]
  
  # Plot ROC curve for test set
  plot.roc(roc_test, col = "red", main = paste("ROC Curve for the SVM Model (Test Set):", name))
  
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
         main = paste("ROC Curves for SVM Model:", name),
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
    paste0("D:/CPE407/THESIS/Result Bi/svm_roc_bi_", name, ".png")
  )
  
  # ----------------- Prepare a Results DataFrame ----------------- #
  
  svm_metrics_df <- data.frame(
    Metric = c("Accuracy", "AUC", "Precision", "Recall", "F1 Score"),
    Train = c(svm_cm_train$overall["Accuracy"], auc_train, metrics_train$precision, metrics_train$recall, metrics_train$f1),
    Validation = c(svm_cm_val$overall["Accuracy"], auc_val, metrics_val$precision, metrics_val$recall, metrics_val$f1),
    Test = c(svm_cm_test$overall["Accuracy"], auc_test, metrics_test$precision, metrics_test$recall, metrics_test$f1)
  )
  svm_metrics_df$Model <- "SVM"
  
  return(list(
    svm_model = svm_model,
    svm_tune_model = svm_tune_model,
    best_tune = best_tune_svm,
    confusion_matrices = list(train = svm_cm_train, validation = svm_cm_val, test = svm_cm_test),
    roc_curves = list(train = roc_train, validation = roc_val, test = roc_test),
    aucs = list(train = auc_train, validation = auc_val, test = auc_test),
    metrics = list(train = metrics_train, validation = metrics_val, test = metrics_test),
    results = svm_metrics_df,
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
