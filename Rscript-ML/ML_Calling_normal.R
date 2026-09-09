# Initialize empty lists for storing results
knn_results_normal_list <- list()
svm_results_normal_list <- list()
xgb_results_normal_list <- list()
rf_results_normal_list  <- list()

# Apply KNN model
knn_results_normal_list <- train_knn_model(training_set, validation_set, testing_set)

saveRDS(knn_results_normal_list$metrics, file = "cfDNA-Sequencing-Analysis/Rscript-ML/knn_tuned_metrics_normal_seed.rds")
saveRDS(knn_results_normal_list$knn_model, file = "cfDNA-Sequencing-Analysis/Rscript-ML/knn_model_normal_seed.rds")
saveRDS(knn_results_normal_list$knn_tune_model, file = "cfDNA-Sequencing-Analysis/Rscript-ML/knn_tune_model_normal_seed.rds")
saveRDS(knn_results_normal_list, file = "cfDNA-Sequencing-Analysis/Rscript-ML/knn_results_normal_seed.rds")

# -------------------------------------------------------------------------#

# Apply SVM model
svm_results_normal_list <- train_svm_model(training_set, validation_set, testing_set)

saveRDS(svm_results_normal_list$metrics, file = "cfDNA-Sequencing-Analysis/Rscript-ML/svm_tuned_metrics_normal_seed.rds")
saveRDS(svm_results_normal_list$svm_model, file = "cfDNA-Sequencing-Analysis/Rscript-ML/svm_model_normal_seed.rds")
saveRDS(svm_results_normal_list$svm_tune_model, file = "cfDNA-Sequencing-Analysis/Rscript-ML/svm_tune_model_normal_seed.rds")
saveRDS(svm_results_normal_list, file = "cfDNA-Sequencing-Analysis/Rscript-ML/svm_results_normal_seed.rds")

# -------------------------------------------------------------------------#

# Apply XGBoost model
xgb_results_normal_list <- train_xgb_model(training_set, validation_set, testing_set)

saveRDS(xgb_results_normal_list$metrics, file = "cfDNA-Sequencing-Analysis/Rscript-ML/xgb_tuned_metrics_normal_seed.rds")
saveRDS(xgb_results_normal_list$xgb_model, file = "cfDNA-Sequencing-Analysis/Rscript-ML/xgb_model_normal_seed.rds")
saveRDS(xgb_results_normal_list$xgb_tune_model, file = "cfDNA-Sequencing-Analysis/Rscript-ML/xgb_tune_model_normal_seed.rds")
saveRDS(xgb_results_normal_list, file = "cfDNA-Sequencing-Analysis/Rscript-ML/xgb_results_normal_seed.rds")

# -------------------------------------------------------------------------#

# Apply Random Forest model
rf_results_normal_list <- train_rf_model(training_set, validation_set, testing_set)

saveRDS(rf_results_normal_list$metrics, file = "cfDNA-Sequencing-Analysis/Rscript-ML/rf_tuned_metrics_normal_seed.rds")
saveRDS(rf_results_normal_list$rf_model, file = "cfDNA-Sequencing-Analysis/Rscript-ML/rf_model_normal_seed.rds")
saveRDS(rf_results_normal_list$rf_tune_model, file = "cfDNA-Sequencing-Analysis/Rscript-ML/rf_tune_model_normal_seed.rds")
saveRDS(rf_results_normal_list, file = "cfDNA-Sequencing-Analysis/Rscript-ML/rf_results_normal_seed.rds")

# -------------------------------------------------------------------------#