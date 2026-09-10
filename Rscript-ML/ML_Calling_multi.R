# Initialize empty lists for storing results
knn_results_multi_list <- list()
svm_results_multi_list <- list()
xgb_results_multi_list <- list()
rf_results_multi_list <- list()

# Apply KNN model
knn_results_multi_list <- train_knn_model(training_set, validation_set, testing_set)

saveRDS(knn_results_multi_list$metrics, file = "cfDNA-Sequencing-Analysis/model/knn_tuned_metrics_multi_seed.rds")
saveRDS(knn_results_multi_list$knn_model, file = "cfDNA-Sequencing-Analysis/model/knn_model_multi_seed.rds")
saveRDS(knn_results_multi_list$knn_tune_model, file = "cfDNA-Sequencing-Analysis/model/knn_tune_model_multi_seed.rds")
saveRDS(knn_results_multi_list, file = "cfDNA-Sequencing-Analysis/model/knn_results_multi_seed.rds")

# -------------------------------------------------------------------------#

# Apply SVM model
svm_results_multi_list <- train_svm_model(training_set, validation_set, testing_set)

saveRDS(svm_results_multi_list$metrics, file = "cfDNA-Sequencing-Analysis/model/svm_tuned_metrics_multi_seed.rds")
saveRDS(svm_results_multi_list$svm_model, file = "cfDNA-Sequencing-Analysis/model/svm_model_multi_seed.rds")
saveRDS(svm_results_multi_list$svm_tune_model, file = "cfDNA-Sequencing-Analysis/model/svm_tune_model_multi_seed.rds")
saveRDS(svm_results_multi_list, file = "cfDNA-Sequencing-Analysis/model/svm_results_multi_seed.rds")

# -------------------------------------------------------------------------#

# Apply XGBoost model
xgb_results_multi_list <- train_xgb_model(training_set, validation_set, testing_set)

saveRDS(xgb_results_multi_list$metrics, file = "cfDNA-Sequencing-Analysis/model/xgb_tuned_metrics_multi_seed.rds")
saveRDS(xgb_results_multi_list$xgb_model, file = "cfDNA-Sequencing-Analysis/model/xgb_model_multi_seed.rds")
saveRDS(xgb_results_multi_list$xgb_tune_model, file = "cfDNA-Sequencing-Analysis/model/xgb_tune_model_multi_seed.rds")
saveRDS(xgb_results_multi_list, file = "cfDNA-Sequencing-Analysis/model/xgb_results_multi_seed.rds")

# -------------------------------------------------------------------------#

# Apply RF model
rf_results_multi_list <- train_rf_model(training_set, validation_set, testing_set)

saveRDS(rf_results_multi_list$metrics, file = "cfDNA-Sequencing-Analysis/model/rf_tuned_metrics_multi_seed.rds")
saveRDS(rf_results_multi_list$rf_model, file = "cfDNA-Sequencing-Analysis/model/rf_model_multi_seed.rds")
saveRDS(rf_results_multi_list$rf_tune_model, file = "cfDNA-Sequencing-Analysis/model/rf_tune_model_multi_seed.rds")
saveRDS(rf_results_multi_list, file = "cfDNA-Sequencing-Analysis/model/rf_results_multi_seed.rds")

# -------------------------------------------------------------------------#