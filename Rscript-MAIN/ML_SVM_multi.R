# Load necessary libraries
library(e1071) # For SVM
library(caret) # For confusionMatrix
library(ggplot2) # For Charts
library(pROC) # For AUC
library(kernlab)

train_svm_model <- function(training_set, validation_set, testing_set) {
  
  # -------------------------------------------------------------------------#
  
  trainControl <- trainControl(
    method = "repeatedcv", number = 10, repeats = 3, 
    verboseIter = FALSE, classProbs = TRUE, allowParallel = TRUE
  )
  
  preProc <- c("center", "scale")
  
  # -------------------------------------------------------------------------#
  
  calculate_metrics <- function(cm) {
    precision <- mean(cm$byClass[, "Pos Pred Value"], na.rm = TRUE)
    recall <- mean(cm$byClass[, "Sensitivity"], na.rm = TRUE)
    specificity <- mean(cm$byClass[, "Specificity"], na.rm = TRUE)
    sensitivity <- recall
    if (is.na(precision) || is.na(recall) || (precision + recall) == 0) {
      f1 <- NA
    } else {
      f1 <- 2 * (precision * recall) / (precision + recall)
    }
    list(precision = precision, recall = recall, f1 = f1, specificity = specificity)
  }
  
  calculate_metrics_by_class <- function(cm) {
    by_class <- as.data.frame(cm$byClass)
    by_class$Class <- rownames(by_class)
    by_class$Precision <- by_class$`Pos Pred Value`
    by_class$Recall <- by_class$Sensitivity
    by_class$F1 <- with(by_class, ifelse(
      is.na(Precision) | is.na(Recall) | (Precision + Recall) == 0,
      NA,
      2 * (Precision * Recall) / (Precision + Recall)
    ))
    by_class[, c("Class", "Precision", "Recall", "F1")]
  }
  
  # ----------------- Initial Model (Training Set) ----------------- #
  
  cat("Processing SVM... \n")
  
  svm_model <- train(tumor_type ~ . - tumor_label - row_id,
                     data = training_set,
                     method = "svmRadial",
                     trControl = trainControl, 
                     metric = "Accuracy",
                     preProcess = preProc)
  
  # Predictions for training set
  y_pred_train_prob <- predict(svm_model, training_set, type = "prob")
  y_pred_train_class <- predict(svm_model, training_set, type = "raw")
  
  svm_cm_train <- confusionMatrix(y_pred_train_class, training_set$tumor_type)
  metrics_train <- calculate_metrics(svm_cm_train)
  roc_train <- multiclass.roc(training_set$tumor_type, y_pred_train_prob)
  auc_train <- roc_train$auc
  
  cat("Training Metrics:\n")
  print(svm_cm_train)
  cat("AUC:", auc_train, "\n")
  
  # Function to plot multi-class ROC curves
  plot_multiclass_roc <- function(prob_matrix, true_labels, dataset_name) {
    par(bg = "white")  # White background
    
    roc_list <- list()
    colors <- c("blue", "green", "red") 
    
    plot(0, 0, type = "n", xlab = "False Positive Rate", ylab = "True Positive Rate",
         xlim = c(1, 0), ylim = c(0, 1), main = paste("One-vs-All ROC Curves for", dataset_name))
    abline(a = 1, b = -1, lty = 2, col = "gray")
    
    i <- 1
    for (class in levels(true_labels)) {
      binary_labels <- ifelse(true_labels == class, 1, 0)
      
      # Ensure at least some positive & negative samples exist
      if (sum(binary_labels) > 0 && sum(binary_labels) < length(binary_labels)) {
        roc_obj <- roc(binary_labels, prob_matrix[, class])
        roc_list[[class]] <- roc_obj
        
        # Use `rev()` to reverse FPR values for left-to-right flip
        lines(rev(roc_obj$specificities), rev(roc_obj$sensitivities), col = colors[i], lwd = 2)
        
        i <- i + 1
      }
    }
    
    # Add legend only if there are valid ROC curves
    if (length(roc_list) > 0) {
      auc_values <- sapply(roc_list, function(r) round(r$auc, 3))
      legend_text <- paste(names(roc_list), " (AUC = ", auc_values, ")", sep = "")
      legend("bottomright", legend = legend_text, col = colors[1:length(roc_list)],
             lwd = 2, box.lty = 0, cex = 0.8)
    }
    
  }
  
  plot_multiclass_roc(y_pred_train_prob, training_set$tumor_type, "SVM Training Set")
  
  # ----------------- Hyperparameter Tuning (Validation Set) ----------------- #
  
  # Hyperparameter tuning for svm
  tune_grid_tune_svm <- expand.grid(
    C = seq(0.1, 5, by = 0.1),
    sigma = seq(0.1, 5, by = 0.1)
  )
  
  svm_tune_model <- train(tumor_type ~ . - tumor_label - row_id,
                          data = training_set,
                          method = "svmRadial", 
                          tuneGrid = tune_grid_tune_svm, 
                          trControl = trainControl,
                          metric = "Accuracy",
                          preProcess = preProc)
  
  best_tune <- svm_tune_model$bestTune
  cat("Best tuning parameters:\n")
  print(best_tune)
  
  y_pred_val_prob <- predict(svm_tune_model, validation_set, type = "prob")
  y_pred_val_class <- predict(svm_tune_model, validation_set, type = "raw")
  
  svm_cm_val <- confusionMatrix(y_pred_val_class, validation_set$tumor_type)
  metrics_val <- calculate_metrics(svm_cm_val)
  roc_val <- multiclass.roc(validation_set$tumor_type, y_pred_val_prob)
  auc_val <- roc_val$auc
  
  cat("Validation Metrics:\n")
  print(svm_cm_val)
  cat("AUC:", auc_val, "\n")
  
  plot_multiclass_roc(y_pred_val_prob, validation_set$tumor_type, "SVM Validation Set")
  
  # ----------------- Testing the Tuned Model (Test Set) ----------------- #
  
  y_pred_test_prob <- predict(svm_tune_model, testing_set, type = "prob")
  y_pred_test_class <- predict(svm_tune_model, testing_set, type = "raw")
  
  svm_cm_test <- confusionMatrix(y_pred_test_class, testing_set$tumor_type)
  metrics_test <- calculate_metrics(svm_cm_test)
  roc_test <- multiclass.roc(testing_set$tumor_type, y_pred_test_prob)
  auc_test <- roc_test$auc
  
  cat("Test Metrics:\n")
  print(svm_cm_test)
  cat("AUC:", auc_test, "\n")
  
  plot_multiclass_roc(y_pred_test_prob, testing_set$tumor_type, "SVM Test Set")
  
  # ----------------- SAVE MULTICLASS ROC (Train + Val + Test) ----------------- #
  
  plot_ovr_roc <- function(prob_matrix, true_labels, dataset_name, file_name) {
    
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
         main = paste("One-vs-All ROC Curves for SVM", dataset_name),
         cex.main = 1.1 * scale,
         cex.lab = 1.1 * scale,
         cex.axis = 1.1 * scale)
    
    abline(a = 0, b = 1, lty = 2, col = "gray")
    
    classes <- levels(true_labels)
    colors <- c("blue", "green", "red")
    
    legend_labels <- c()
    
    for (i in seq_along(classes)) {
      
      class <- classes[i]
      
      binary_labels <- ifelse(true_labels == class, 1, 0)
      
      if (sum(binary_labels) > 0 && sum(binary_labels) < length(binary_labels)) {
        
        roc_obj <- pROC::roc(binary_labels, prob_matrix[, class])
        auc_val <- pROC::auc(roc_obj)
        
        lines(1 - roc_obj$specificities,
              roc_obj$sensitivities,
              col = colors[i],
              lwd = 2,
              lty = 1)
        
        legend_labels <- c(legend_labels,
                           paste(class, "(AUC =", round(auc_val, 3), ")"))
      }
    }
    
    legend("bottomright",
           legend = legend_labels,
           col = colors[1:length(legend_labels)],
           lwd = 2,
           cex = 1,
           bty = "o")
    
    dev.off()
  }
  
  # Train
  plot_ovr_roc(y_pred_train_prob,
               training_set$tumor_type,
               "Training Set",
               "D:/CPE407/THESIS/Result Multi/svm_roc_multi_train.png")
  
  # Validation
  plot_ovr_roc(y_pred_val_prob,
               validation_set$tumor_type,
               "Validation Set",
               "D:/CPE407/THESIS/Result Multi/svm_roc_multi_validation.png")
  
  # Test
  plot_ovr_roc(y_pred_test_prob,
               testing_set$tumor_type,
               "Test Set",
               "D:/CPE407/THESIS/Result Multi/svm_roc_multi_test.png")
  
  # ----------------- Prepare a Results DataFrame ----------------- #
  
  per_class_metrics_train <- calculate_metrics_by_class(svm_cm_train)
  per_class_metrics_val <- calculate_metrics_by_class(svm_cm_val)
  per_class_metrics_test <- calculate_metrics_by_class(svm_cm_test)
  per_class_all <- rbind(
    transform(per_class_metrics_train, Set = "Train"),
    transform(per_class_metrics_val, Set = "Validation"),
    transform(per_class_metrics_test, Set = "Test")
  )
  
  # Overall Performance Table
  overall_summary_df <- data.frame(
    Set = c("Train", "Validation", "Test"),
    Accuracy = c(svm_cm_train$overall["Accuracy"],
                 svm_cm_val$overall["Accuracy"],
                 svm_cm_test$overall["Accuracy"]),
    CI_Lower = c(svm_cm_train$overall["AccuracyLower"],
                 svm_cm_val$overall["AccuracyLower"],
                 svm_cm_test$overall["AccuracyLower"]),
    CI_Upper = c(svm_cm_train$overall["AccuracyUpper"],
                 svm_cm_val$overall["AccuracyUpper"],
                 svm_cm_test$overall["AccuracyUpper"]),
    AUC = c(auc_train, auc_val, auc_test),
    Precision = c(metrics_train$precision, metrics_val$precision, metrics_test$precision),
    Recall = c(metrics_train$recall, metrics_val$recall, metrics_test$recall),
    F1 = c(metrics_train$f1, metrics_val$f1, metrics_test$f1),
    Model = "SVM"
  )
  
  svm_metrics_df <- data.frame(
    Metric = c("Accuracy", "AUC", "Precision", "Recall", "F1 Score"),
    Train = c(svm_cm_train$overall["Accuracy"], auc_train, metrics_train$precision, metrics_train$recall, metrics_train$f1),
    Validation = c(svm_cm_val$overall["Accuracy"], auc_val, metrics_val$precision, metrics_val$recall, metrics_val$f1),
    Test = c(svm_cm_test$overall["Accuracy"], auc_test, metrics_test$precision, metrics_test$recall, metrics_test$f1)
  )
  svm_metrics_df$Model <- "SVM"
  
  # ----------------- Return Results ----------------- #
  
  return(list(
    svm_model = svm_model,
    svm_tune_model = svm_tune_model,
    best_tune = best_tune,
    confusion_matrices = list(train = svm_cm_train, validation = svm_cm_val, test = svm_cm_test),
    roc_curves = list(train = roc_train, validation = roc_val, test = roc_test),
    aucs = list(train = auc_train, validation = auc_val, test = auc_test),
    metrics = list(train = metrics_train, validation = metrics_val, test = metrics_test),
    overall_metrics = overall_summary_df,
    per_class_metrics = list(train = per_class_metrics_train, 
                             validation = per_class_metrics_val, 
                             test = per_class_metrics_test),
    results = svm_metrics_df,
    predictions = list(
      train = list(
        Row_id = training_set$row_id,
        probabilities = y_pred_train_prob,
        classes = y_pred_train_class,
        actual = training_set$tumor_type
      ),
      validation = list(
        Row_id = validation_set$row_id,
        probabilities = y_pred_val_prob,
        classes = y_pred_val_class,
        actual = validation_set$tumor_type
      ),
      test = list(
        Row_id = testing_set$row_id,
        probabilities = y_pred_test_prob,
        classes = y_pred_test_class,
        actual = testing_set$tumor_type
      )
    )
  ))
  
}