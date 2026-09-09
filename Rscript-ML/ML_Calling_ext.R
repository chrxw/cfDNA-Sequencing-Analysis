# Initialize empty lists for storing results
knn_results_bi_list <- list()
svm_results_bi_list <- list()
xgb_results_bi_list <- list()
rf_results_bi_list <- list()

# Loop over each dataset and apply the models
for (name in names(bi_datasets)) {
  
  ds <- bi_datasets[[name]]
  knn_results <- train_knn_model(
    training_set   = ds$train,
    validation_set = ds$valid,
    testing_set    = ds$test,
    name      = name
  )
  
  knn_results_bi_list[[name]] <- knn_results
  
  saveRDS(knn_results$knn_tuned_metrics_df, file = paste0("cfDNA-Sequencing-Analysis/Rscript-ML/knn_tuned_metrics_bi_", name, "_seed.rds"))
  saveRDS(knn_results$knn_model, file = paste0("cfDNA-Sequencing-Analysis/Rscript-ML/knn_model_bi_", name, "_seed.rds"))
  saveRDS(knn_results$knn_tune_model, file = paste0("cfDNA-Sequencing-Analysis/Rscript-ML/knn_tune_model_bi_", name, "_seed.rds"))
  saveRDS(knn_results_bi_list, file = paste0("cfDNA-Sequencing-Analysis/Rscript-ML/knn_results_bi_list_seed.rds"))
  
}

# -------------------------------------------------------------------------#

for (name in names(bi_datasets)) {
  
  ds <- bi_datasets[[name]]
  svm_results <- train_svm_model(
    training_set   = ds$train,
    validation_set = ds$valid,
    testing_set    = ds$test,
    name      = name
  )
  
  svm_results_bi_list[[name]] <- svm_results
  
  saveRDS(svm_results$svm_tuned_metrics_df, file = paste0("cfDNA-Sequencing-Analysis/Rscript-ML/svm_tuned_metrics_bi_", name, "_seed.rds"))
  saveRDS(svm_results$svm_model, file = paste0("cfDNA-Sequencing-Analysis/Rscript-ML/svm_model_bi_", name, "_seed.rds"))
  saveRDS(svm_results$svm_tune_model, file = paste0("cfDNA-Sequencing-Analysis/Rscript-ML/svm_tune_model_bi_", name, "_seed.rds"))
  saveRDS(svm_results_bi_list, file = paste0("cfDNA-Sequencing-Analysis/Rscript-ML/svm_results_bi_list_seed.rds"))
  
}

# -------------------------------------------------------------------------#

for (name in names(bi_datasets)) {
  
  ds <- bi_datasets[[name]]
  xgb_results <- train_xgb_model(
    training_set   = ds$train,
    validation_set = ds$valid,
    testing_set    = ds$test,
    name      = name
  )
  
  xgb_results_bi_list[[name]] <- xgb_results
  
  saveRDS(xgb_results$xgb_tuned_metrics_df, file = paste0("cfDNA-Sequencing-Analysis/Rscript-ML/xgb_tuned_metrics_bi_", name, "_seed.rds"))
  saveRDS(xgb_results$xgb_model, file = paste0("cfDNA-Sequencing-Analysis/Rscript-ML/xgb_model_bi_", name, "_seed.rds"))
  saveRDS(xgb_results$xgb_tune_model, file = paste0("cfDNA-Sequencing-Analysis/Rscript-ML/xgb_tune_model_bi_", name, "_seed.rds"))
  saveRDS(xgb_results_bi_list, file = paste0("cfDNA-Sequencing-Analysis/Rscript-ML/xgb_results_bi_list_seed.rds"))
  
}

# -------------------------------------------------------------------------#

for (name in names(bi_datasets)) {
  
  ds <- bi_datasets[[name]]
  rf_results <- train_rf_model(
    training_set   = ds$train,
    validation_set = ds$valid,
    testing_set    = ds$test,
    name      = name
  )
  
  rf_results_bi_list[[name]] <- rf_results
  
  saveRDS(rf_results$rf_tuned_metrics_df, file = paste0("cfDNA-Sequencing-Analysis/Rscript-ML/rf_tuned_metrics_bi_", name, "_seed.rds"))
  saveRDS(rf_results$rf_model, file = paste0("cfDNA-Sequencing-Analysis/Rscript-ML/rf_model_bi_", name, "_seed.rds"))
  saveRDS(rf_results$rf_tune_model, file = paste0("cfDNA-Sequencing-Analysis/Rscript-ML/rf_tune_model_bi_", name, "_seed.rds"))
  saveRDS(rf_results_bi_list, file = paste0("cfDNA-Sequencing-Analysis/Rscript-ML/rf_results_bi_list_seed.rds"))
  
}
