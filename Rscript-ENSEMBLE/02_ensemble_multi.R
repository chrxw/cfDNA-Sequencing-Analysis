# ============================================================
#  MULTI-CLASS ENSEMBLE — STEP 2: ENSEMBLE MODEL
#
#  วัตถุประสงค์:
#    1) โหลดผลจาก Step 1 (หรือรัน evaluation ใหม่)
#    2) ประเมิน top 3 จาก 4 single models (เรียงตาม Macro-AUC บน test set)
#    3) สร้าง Hard Vote Ensemble (majority vote + tie-break)
#    4) สร้าง Soft Vote Ensemble (average probabilities)
#    5) ประเมิน ensemble ทั้งสอง
#    6) เปรียบเทียบ: 4 single models + 2 ensemble (overall + per-class)
#    7) เปรียบเทียบ row-by-row: ensemble vs single models (อ่านจาก xlsx เพื่อน)
#    8) บันทึกผลลัพธ์ครบถ้วน (xlsx หลายชีต + plots)
#
#  Inputs:
#    results/01_single_model/step1_results.rds  (from Step 1)
#    data/reference/ML_predictions_multi.xlsx  (friend's xlsx)
#
#  Outputs:
#    results/02_ensemble/ensemble_results.xlsx
#    results/02_ensemble/plots/*.png
#    results/02_ensemble/ensemble_model.rds
# ============================================================

# ── 0. Libraries ─────────────────────────────────────────────
suppressPackageStartupMessages({
  library(tidyverse)
  library(caret)
  library(pROC)
  library(openxlsx)
  library(ggplot2)
  library(gridExtra)
  library(scales)
})

set.seed(42)

cat("╔══════════════════════════════════════════════════════╗\n")
cat("║  STEP 2: ENSEMBLE MODEL — MULTI-CLASS                ║\n")
cat("╚══════════════════════════════════════════════════════╝\n\n")

# ── 1. Paths (คำนวณจากตำแหน่งโฟลเดอร์ — see 00_config.R) ─────
local({
  cand <- c("Rscript-ENSEMBLE/00_config.R", "00_config.R", "../Rscript-ENSEMBLE/00_config.R")
  hit  <- cand[file.exists(cand)]
  if (!length(hit))
    stop("ไม่พบ 00_config.R — setwd() ไปที่ repo root หรือโฟลเดอร์ Rscript-ENSEMBLE ก่อน", call. = FALSE)
  p <- normalizePath(hit[1], winslash = "/")
  assign(".ENSEMBLE_CFG_PATH", p, envir = globalenv())
  sys.source(p, envir = globalenv())
})
check_inputs()

OUT_DIR <- STEP2_DIR
PLOT_DIR     <- file.path(OUT_DIR, "plots")

dir.create(PLOT_DIR, recursive = TRUE, showWarnings = FALSE)

cat("── Paths ──\n")
cat("  Step1 results:", STEP1_DIR, "\n")
cat("  Output dir   :", OUT_DIR,   "\n\n")

# ── 2. Load Step 1 Results (or re-evaluate) ──────────────────
step1_rds <- file.path(STEP1_DIR, "step1_results.rds")

if (file.exists(step1_rds)) {
  cat("=== Loading Step 1 results ===\n")
  s1 <- readRDS(step1_rds)
  all_results       <- s1$all_results
  overall_metrics   <- s1$overall_metrics
  per_class_metrics <- s1$per_class_metrics
  all_predictions   <- s1$all_predictions
  friend_preds_all  <- s1$friend_preds_all
  CLASS_LEVELS      <- s1$CLASS_LEVELS
  N_CLASSES         <- s1$N_CLASSES
  train_set         <- s1$train_set
  val_set           <- s1$val_set
  test_set          <- s1$test_set
  cat("  Loaded. Classes:", paste(CLASS_LEVELS, collapse=", "), "\n")
} else {
  cat("  WARNING: step1_results.rds not found. Loading data and models directly.\n")

  suppressPackageStartupMessages(library(openxlsx))

  train_set <- readRDS(file.path(DF_DIR, "ML_multi_train.rds"))
  val_set   <- readRDS(file.path(DF_DIR, "ML_multi_val.rds"))
  test_set  <- readRDS(file.path(DF_DIR, "ML_multi_test.rds"))

  CLASS_LEVELS <- sort(unique(c(as.character(train_set$tumor_type),
                                  as.character(val_set$tumor_type),
                                  as.character(test_set$tumor_type))))
  N_CLASSES <- length(CLASS_LEVELS)

  train_set$tumor_type <- factor(train_set$tumor_type, levels = CLASS_LEVELS)
  val_set$tumor_type   <- factor(val_set$tumor_type,   levels = CLASS_LEVELS)
  test_set$tumor_type  <- factor(test_set$tumor_type,  levels = CLASS_LEVELS)

  models <- list(
    KNN = readRDS(file.path(MODEL_DIR, "knn_tune_model_multi_seed.rds")),
    SVM = readRDS(file.path(MODEL_DIR, "svm_tune_model_multi_seed.rds")),
    XGB = readRDS(file.path(MODEL_DIR, "xgb_tune_model_multi_seed.rds")),
    RF  = readRDS(file.path(MODEL_DIR, "rf_tune_model_multi_seed.rds"))
  )

  # ── Inline helper functions (duplicated from step 1 for standalone mode) ──
  compute_macro_auc <- function(y_true, prob_mat, class_lvls) {
    auc_vals <- sapply(class_lvls, function(cls) {
      bin <- as.numeric(y_true == cls)
      if (length(unique(bin)) < 2) return(NA_real_)
      col <- if (cls %in% colnames(prob_mat)) prob_mat[, cls] else prob_mat[, which(class_lvls == cls)]
      tryCatch(as.numeric(pROC::auc(pROC::roc(bin, col, quiet = TRUE))), error = function(e) NA_real_)
    })
    mean(auc_vals, na.rm = TRUE)
  }

  compute_per_class_auc <- function(y_true, prob_mat, class_lvls) {
    setNames(sapply(class_lvls, function(cls) {
      bin <- as.numeric(y_true == cls)
      if (length(unique(bin)) < 2) return(NA_real_)
      col <- if (cls %in% colnames(prob_mat)) prob_mat[, cls] else NA_real_
      if (all(is.na(col))) return(NA_real_)
      tryCatch(as.numeric(pROC::auc(pROC::roc(bin, col, quiet = TRUE))), error = function(e) NA_real_)
    }), class_lvls)
  }

  evaluate_on_set <- function(model, dataset, class_lvls, set_name, model_name) {
    dataset$tumor_type <- factor(dataset$tumor_type, levels = class_lvls)
    y_true <- dataset$tumor_type
    pred_class <- factor(predict(model, newdata = dataset), levels = class_lvls)
    prob_mat <- tryCatch({
      p <- as.matrix(predict(model, newdata = dataset, type = "prob"))
      if (!is.null(colnames(p)) && all(class_lvls %in% colnames(p)))
        p[, class_lvls, drop = FALSE]
      else { colnames(p) <- class_lvls; p }
    }, error = function(e) {
      mat <- matrix(0, nrow = nrow(dataset), ncol = length(class_lvls),
                    dimnames = list(NULL, class_lvls))
      for (i in seq_along(pred_class)) mat[i, as.character(pred_class[i])] <- 1
      mat
    })
    cm <- confusionMatrix(pred_class, y_true)
    macro_auc <- compute_macro_auc(y_true, prob_mat, class_lvls)
    cls_aucs  <- compute_per_class_auc(y_true, prob_mat, class_lvls)
    overall <- data.frame(
      Model = model_name, Set = set_name,
      Accuracy = round(as.numeric(cm$overall["Accuracy"]), 4),
      Kappa    = round(as.numeric(cm$overall["Kappa"]),    4),
      AccuracyLower95 = round(as.numeric(cm$overall["AccuracyLower"]), 4),
      AccuracyUpper95 = round(as.numeric(cm$overall["AccuracyUpper"]), 4),
      Macro_AUC         = round(macro_auc, 4),
      Macro_Sensitivity = round(mean(cm$byClass[, "Sensitivity"],    na.rm=TRUE), 4),
      Macro_Specificity = round(mean(cm$byClass[, "Specificity"],    na.rm=TRUE), 4),
      Macro_Precision   = round(mean(cm$byClass[, "Pos Pred Value"], na.rm=TRUE), 4),
      Macro_F1          = round(mean(cm$byClass[, "F1"],             na.rm=TRUE), 4),
      stringsAsFactors = FALSE
    )
    by_cls <- as.data.frame(cm$byClass)
    by_cls$Class <- gsub("^Class: ", "", rownames(by_cls))
    by_cls$Model <- model_name; by_cls$Set <- set_name
    by_cls$AUC <- cls_aucs[by_cls$Class]
    rownames(by_cls) <- NULL
    by_cls <- by_cls %>%
      select(Model, Set, Class, Sensitivity, Specificity,
             Precision = `Pos Pred Value`, NPV = `Neg Pred Value`, F1, AUC) %>%
      mutate(across(where(is.numeric), ~ round(.x, 4)))
    row_id_col <- if ("row_id" %in% names(dataset)) dataset$row_id else seq_len(nrow(dataset))
    pred_rows <- data.frame(
      Model = model_name, Set = set_name, Row_id = row_id_col,
      Actual = as.character(y_true), Predicted = as.character(pred_class),
      Correct = as.character(y_true) == as.character(pred_class),
      stringsAsFactors = FALSE
    )
    prob_cols <- as.data.frame(prob_mat); colnames(prob_cols) <- paste0("Prob_", class_lvls)
    pred_rows <- cbind(pred_rows, round(prob_cols, 6))
    list(overall = overall, by_class = by_cls, pred_rows = pred_rows,
         cm = cm, prob_mat = prob_mat, pred_class = pred_class, y_true = y_true)
  }

  all_results <- list()
  for (nm in names(models)) {
    all_results[[nm]] <- list(
      Train      = evaluate_on_set(models[[nm]], train_set, CLASS_LEVELS, "Train",      nm),
      Validation = evaluate_on_set(models[[nm]], val_set,   CLASS_LEVELS, "Validation", nm),
      Test       = evaluate_on_set(models[[nm]], test_set,  CLASS_LEVELS, "Test",       nm)
    )
  }
  overall_metrics   <- bind_rows(lapply(names(all_results), function(nm)
    bind_rows(lapply(names(all_results[[nm]]), function(sn) all_results[[nm]][[sn]]$overall))))
  per_class_metrics <- bind_rows(lapply(names(all_results), function(nm)
    bind_rows(lapply(names(all_results[[nm]]), function(sn) all_results[[nm]][[sn]]$by_class))))
  all_predictions   <- bind_rows(lapply(names(all_results), function(nm)
    bind_rows(lapply(names(all_results[[nm]]), function(sn) all_results[[nm]][[sn]]$pred_rows))))
  friend_preds_all  <- data.frame()
}

# ── 3. Shared helpers ──────────────────────────────────────────
compute_macro_auc <- function(y_true, prob_mat, class_lvls) {
  auc_vals <- sapply(class_lvls, function(cls) {
    bin <- as.numeric(y_true == cls)
    if (length(unique(bin)) < 2) return(NA_real_)
    col <- if (cls %in% colnames(prob_mat)) prob_mat[, cls] else prob_mat[, which(class_lvls == cls)]
    tryCatch(as.numeric(pROC::auc(pROC::roc(bin, col, quiet = TRUE))), error = function(e) NA_real_)
  })
  mean(auc_vals, na.rm = TRUE)
}

compute_per_class_auc <- function(y_true, prob_mat, class_lvls) {
  setNames(sapply(class_lvls, function(cls) {
    bin <- as.numeric(y_true == cls)
    if (length(unique(bin)) < 2) return(NA_real_)
    col <- if (cls %in% colnames(prob_mat)) prob_mat[, cls] else NA_real_
    if (all(is.na(col))) return(NA_real_)
    tryCatch(as.numeric(pROC::auc(pROC::roc(bin, col, quiet = TRUE))), error = function(e) NA_real_)
  }), class_lvls)
}

build_overall_row <- function(model_name, pred_class, prob_mat,
                               y_true, class_lvls, extra_cols = list()) {
  cm <- confusionMatrix(factor(pred_class, levels = class_lvls),
                        factor(y_true,     levels = class_lvls))
  macro_auc <- compute_macro_auc(y_true, prob_mat, class_lvls)
  row <- data.frame(
    Model             = model_name,
    Accuracy          = round(as.numeric(cm$overall["Accuracy"]),      4),
    Kappa             = round(as.numeric(cm$overall["Kappa"]),          4),
    AccuracyLower95   = round(as.numeric(cm$overall["AccuracyLower"]), 4),
    AccuracyUpper95   = round(as.numeric(cm$overall["AccuracyUpper"]), 4),
    Macro_AUC         = round(macro_auc,                                4),
    Macro_Sensitivity = round(mean(cm$byClass[, "Sensitivity"],    na.rm=TRUE), 4),
    Macro_Specificity = round(mean(cm$byClass[, "Specificity"],    na.rm=TRUE), 4),
    Macro_Precision   = round(mean(cm$byClass[, "Pos Pred Value"], na.rm=TRUE), 4),
    Macro_F1          = round(mean(cm$byClass[, "F1"],             na.rm=TRUE), 4),
    stringsAsFactors  = FALSE
  )
  for (nm in names(extra_cols)) row[[nm]] <- extra_cols[[nm]]
  list(metrics = row, cm = cm, macro_auc = macro_auc)
}

build_per_class_row <- function(model_name, pred_class, prob_mat,
                                 y_true, class_lvls) {
  cm <- confusionMatrix(factor(pred_class, levels = class_lvls),
                        factor(y_true,     levels = class_lvls))
  cls_aucs <- compute_per_class_auc(y_true, prob_mat, class_lvls)
  by_cls   <- as.data.frame(cm$byClass)
  by_cls$Class <- gsub("^Class: ", "", rownames(by_cls))
  by_cls$Model <- model_name
  by_cls$AUC   <- cls_aucs[by_cls$Class]
  rownames(by_cls) <- NULL
  by_cls %>%
    select(Model, Class, Sensitivity, Specificity,
           Precision = `Pos Pred Value`, NPV = `Neg Pred Value`, F1, AUC) %>%
    mutate(across(where(is.numeric), ~ round(.x, 4)))
}

# Extract test-set predictions from Step 1
get_test_result <- function(model_name) {
  all_results[[model_name]][["Test"]]
}

# ── 4. Step A: Model Ranking by Test Macro-AUC ───────────────
cat("\n=== Step A: Model Ranking (Test Set Macro-AUC) ===\n")

test_eval <- overall_metrics %>%
  filter(Set == "Test") %>%
  arrange(desc(Macro_AUC)) %>%
  mutate(Rank = row_number())

cat("\n── Test Set Performance (all 4 single models) ──\n")
print(test_eval %>% select(Rank, Model, Accuracy, Macro_AUC, Macro_F1,
                             Macro_Sensitivity, Macro_Specificity))

top3_names      <- test_eval$Model[1:3]
best_model_name <- top3_names[1]

cat(sprintf("\nTop 3 (by Macro-AUC): %s\n", paste(top3_names, collapse = " > ")))
cat(sprintf("Best model (tie-break): %s\n", best_model_name))

# ── 5. Prepare Top-3 Predictions for Ensemble ─────────────────
cat("\n=== Step B: Preparing top-3 predictions for ensemble ===\n")

top3_results <- lapply(top3_names, function(nm) get_test_result(nm))
names(top3_results) <- top3_names

y_test     <- get_test_result(best_model_name)$y_true
row_ids    <- if ("row_id" %in% names(test_set)) test_set$row_id else seq_len(nrow(test_set))

# Get probability matrices (all top 3)
prob_arrays <- lapply(top3_results, function(r) {
  p <- r$prob_mat
  if (!all(CLASS_LEVELS %in% colnames(p))) stop("Missing class columns in probability matrix")
  p[, CLASS_LEVELS, drop = FALSE]
})

# Ensemble averaged probability (used for soft vote and tie-breaking)
ensemble_prob_top3 <- Reduce("+", prob_arrays) / length(prob_arrays)

# ── 6. Build Hard Vote Ensemble ───────────────────────────────
cat("\n=== Step C: Hard Vote Ensemble ===\n")

top3_pred_df <- map_dfc(top3_results, ~ as.character(.x$pred_class)) %>%
  setNames(top3_names)

tie_break_preds <- top3_results[[best_model_name]]$pred_class

majority_vote <- function(row_vec, tb_pred) {
  tbl     <- table(row_vec)
  winners <- names(tbl)[tbl == max(tbl)]
  if (length(winners) == 1) winners else as.character(tb_pred)
}

hard_vote_class <- factor(
  sapply(seq_len(nrow(top3_pred_df)), function(i)
    majority_vote(as.character(top3_pred_df[i, ]), as.character(tie_break_preds[i]))),
  levels = CLASS_LEVELS
)

hard_vote_prob <- ensemble_prob_top3  # averaged prob for AUC computation

hv_eval <- build_overall_row("Ensemble_HardVote (Top3)", hard_vote_class,
                              hard_vote_prob, y_test, CLASS_LEVELS,
                              extra_cols = list(Strategy = "Hard Vote", Top_N = 3,
                                                Top3_Models = paste(top3_names, collapse="+")))
hv_per_class <- build_per_class_row("Ensemble_HardVote (Top3)", hard_vote_class,
                                     hard_vote_prob, y_test, CLASS_LEVELS)

cat(sprintf("  Hard Vote Accuracy : %.4f\n", hv_eval$metrics$Accuracy))
cat(sprintf("  Hard Vote Macro-AUC: %.4f\n", hv_eval$metrics$Macro_AUC))
cat(sprintf("  Hard Vote Macro-F1 : %.4f\n", hv_eval$metrics$Macro_F1))

# ── 7. Build Soft Vote Ensemble ───────────────────────────────
cat("\n=== Step D: Soft Vote Ensemble ===\n")

soft_vote_prob  <- ensemble_prob_top3  # same averaged probability
soft_vote_class <- factor(
  CLASS_LEVELS[max.col(soft_vote_prob, ties.method = "first")],
  levels = CLASS_LEVELS
)

sv_eval <- build_overall_row("Ensemble_SoftVote (Top3)", soft_vote_class,
                              soft_vote_prob, y_test, CLASS_LEVELS,
                              extra_cols = list(Strategy = "Soft Vote", Top_N = 3,
                                                Top3_Models = paste(top3_names, collapse="+")))
sv_per_class <- build_per_class_row("Ensemble_SoftVote (Top3)", soft_vote_class,
                                     soft_vote_prob, y_test, CLASS_LEVELS)

cat(sprintf("  Soft Vote Accuracy : %.4f\n", sv_eval$metrics$Accuracy))
cat(sprintf("  Soft Vote Macro-AUC: %.4f\n", sv_eval$metrics$Macro_AUC))
cat(sprintf("  Soft Vote Macro-F1 : %.4f\n", sv_eval$metrics$Macro_F1))

# ── 8. Full Comparison: 4 Single + 2 Ensemble ─────────────────
cat("\n=== Step E: Full Model Comparison ===\n")

single_test_metrics <- overall_metrics %>%
  filter(Set == "Test") %>%
  select(-Set) %>%
  mutate(Strategy = "Single Model", Top_N = NA_integer_, Top3_Models = NA_character_)

ensemble_metrics <- bind_rows(
  hv_eval$metrics %>% mutate(Set = "Test"),
  sv_eval$metrics %>% mutate(Set = "Test")
) %>% select(-Set)

full_comparison <- bind_rows(single_test_metrics, ensemble_metrics) %>%
  arrange(desc(Macro_AUC)) %>%
  mutate(Rank = row_number())

cat("\n══ Full Model Comparison (Test Set) ══\n")
print(full_comparison %>% select(Rank, Model, Accuracy, Macro_AUC, Macro_F1,
                                   Macro_Sensitivity, Macro_Specificity))

# Per-class comparison (all models + ensemble)
single_per_class_test <- per_class_metrics %>% filter(Set == "Test") %>% select(-Set)
ensemble_per_class    <- bind_rows(hv_per_class, sv_per_class)

full_per_class <- bind_rows(single_per_class_test, ensemble_per_class)

# ── 9. Soft Vote Probabilities Table ─────────────────────────
sv_prob_df <- as.data.frame(round(soft_vote_prob, 6))
colnames(sv_prob_df) <- paste0("SoftProb_", CLASS_LEVELS)
sv_prob_df$Row_id    <- row_ids
sv_prob_df$Actual    <- as.character(y_test)
sv_prob_df$SoftVote_Predicted <- as.character(soft_vote_class)
sv_prob_df$HardVote_Predicted <- as.character(hard_vote_class)
sv_prob_df$SoftVote_Correct   <- sv_prob_df$Actual == sv_prob_df$SoftVote_Predicted
sv_prob_df$HardVote_Correct   <- sv_prob_df$Actual == sv_prob_df$HardVote_Predicted
sv_prob_df$Votes_Agree        <- sv_prob_df$SoftVote_Predicted == sv_prob_df$HardVote_Predicted
sv_prob_df <- sv_prob_df %>% select(Row_id, Actual,
                                     SoftVote_Predicted, HardVote_Predicted,
                                     SoftVote_Correct, HardVote_Correct, Votes_Agree,
                                     starts_with("SoftProb_"))

# ── 10. Row-by-Row Predictions — All 6 Models ────────────────
cat("\n=== Step F: Row-by-row predictions — all 6 models ===\n")

# Single model test predictions
single_test_preds <- all_predictions %>%
  filter(Set == "Test") %>%
  select(Model, Row_id, Actual, Predicted, Correct, starts_with("Prob_"))

# Ensemble predictions
ens_hv_rows <- data.frame(
  Model     = "Ensemble_HardVote",
  Row_id    = row_ids,
  Actual    = as.character(y_test),
  Predicted = as.character(hard_vote_class),
  Correct   = as.character(y_test) == as.character(hard_vote_class),
  stringsAsFactors = FALSE
)
ens_hv_prob <- as.data.frame(round(hard_vote_prob, 6))
colnames(ens_hv_prob) <- paste0("Prob_", CLASS_LEVELS)
ens_hv_rows <- cbind(ens_hv_rows, ens_hv_prob)

ens_sv_rows <- data.frame(
  Model     = "Ensemble_SoftVote",
  Row_id    = row_ids,
  Actual    = as.character(y_test),
  Predicted = as.character(soft_vote_class),
  Correct   = as.character(y_test) == as.character(soft_vote_class),
  stringsAsFactors = FALSE
)
ens_sv_prob <- as.data.frame(round(soft_vote_prob, 6))
colnames(ens_sv_prob) <- paste0("Prob_", CLASS_LEVELS)
ens_sv_rows <- cbind(ens_sv_rows, ens_sv_prob)

all_6_preds <- bind_rows(single_test_preds, ens_hv_rows, ens_sv_rows)

# ── 11. Comprehensive Row-by-Row Comparison (Wide Format) ─────
cat("  Building wide comparison table...\n")

all_model_names <- c(names(all_results), "Ensemble_HardVote", "Ensemble_SoftVote")

# For each model, extract predicted class per row
pred_wide <- data.frame(Row_id = row_ids, Actual = as.character(y_test),
                          stringsAsFactors = FALSE)

for (nm in names(all_results)) {
  r <- get_test_result(nm)
  pred_wide[[paste0(nm, "_Pred")]]    <- as.character(r$pred_class)
  pred_wide[[paste0(nm, "_Correct")]] <- as.character(y_test) == as.character(r$pred_class)
}
pred_wide[["HardVote_Pred"]]    <- as.character(hard_vote_class)
pred_wide[["HardVote_Correct"]] <- as.character(y_test) == as.character(hard_vote_class)
pred_wide[["SoftVote_Pred"]]    <- as.character(soft_vote_class)
pred_wide[["SoftVote_Correct"]] <- as.character(y_test) == as.character(soft_vote_class)

# Correct model count per row (out of 4 single models)
correct_cols <- paste0(names(all_results), "_Correct")
pred_wide$N_SingleModels_Correct <- rowSums(pred_wide[, correct_cols])
pred_wide$All_Single_Agree       <- apply(
  pred_wide[, paste0(names(all_results), "_Pred")], 1,
  function(r) length(unique(r)) == 1
)
pred_wide$HardVote_Matches_SoftVote <- pred_wide$HardVote_Pred == pred_wide$SoftVote_Pred

# ── 12. Row-by-row comparison with Friend's xlsx ──────────────
cat("  Comparing with friend's xlsx...\n")

friend_comparison <- data.frame()
friend_compare_summary <- data.frame()

if (!is.null(friend_preds_all) && nrow(friend_preds_all) > 0) {

  detect_col <- function(df, patterns) {
    hits <- names(df)[grepl(paste(patterns, collapse="|"), names(df), ignore.case=TRUE)]
    if (length(hits) > 0) hits[1] else NA_character_
  }

  friend_rowid_col  <- detect_col(friend_preds_all, c("row_id","rowid","row.id"))
  friend_pred_col   <- detect_col(friend_preds_all, c("predicted","prediction","pred_class"))
  friend_actual_col <- detect_col(friend_preds_all, c("actual","true_label","true"))
  friend_set_col    <- detect_col(friend_preds_all, c("^set$","dataset","split"))
  friend_model_col  <- detect_col(friend_preds_all, c("^model$","model_name"))

  rows_to_compare <- pred_wide  # has Row_id, Actual, and all model predictions

  compare_rows <- list()
  compare_summary <- list()

  # Load by sheet if available
  friend_by_model <- list()
  for (nm in names(all_results)) {
    if (nm %in% names(s1$friend_preds_all %>% {NULL})) {
      # handled below
    }
  }

  # Re-load friend xlsx if needed
  friend_xlsx <- file.path(FRIEND_RESULT_DIR, "ML_predictions_multi.xlsx")
  if (file.exists(friend_xlsx)) {
    sheet_names <- tryCatch(getSheetNames(friend_xlsx), error = function(e) character(0))
    for (sh in sheet_names) {
      df <- tryCatch(read.xlsx(friend_xlsx, sheet = sh), error = function(e) NULL)
      if (!is.null(df)) friend_by_model[[sh]] <- df
    }
  }

  for (nm in names(all_results)) {
    # Find friend data for this model
    friend_model_df <- NULL
    if (nm %in% names(friend_by_model)) {
      friend_model_df <- friend_by_model[[nm]]
    } else if (!is.na(friend_model_col)) {
      friend_model_df <- friend_preds_all %>%
        filter(grepl(nm, .[[friend_model_col]], ignore.case=TRUE))
    }
    if (is.null(friend_model_df) || nrow(friend_model_df) == 0) next

    # Filter to test set
    if (!is.na(friend_set_col)) {
      test_rows <- friend_model_df %>%
        filter(grepl("test", .[[friend_set_col]], ignore.case=TRUE))
      if (nrow(test_rows) > 0) friend_model_df <- test_rows
    }

    if (is.na(friend_rowid_col) || is.na(friend_pred_col)) next

    friend_sub <- friend_model_df %>%
      select(Row_id = all_of(friend_rowid_col),
             Friend_Predicted = all_of(friend_pred_col))
    friend_sub$Row_id <- as.integer(friend_sub$Row_id)

    if (!is.na(friend_actual_col)) {
      friend_sub$Friend_Actual <- as.character(friend_model_df[[friend_actual_col]])
    }

    merged <- merge(
      pred_wide %>% select(Row_id, Actual,
                            Our_Predicted     = paste0(nm, "_Pred"),
                            Our_Correct       = paste0(nm, "_Correct"),
                            HV_Predicted      = HardVote_Pred,
                            HV_Correct        = HardVote_Correct,
                            SV_Predicted      = SoftVote_Pred,
                            SV_Correct        = SoftVote_Correct),
      friend_sub,
      by = "Row_id", all.x = TRUE
    )
    merged$Model              <- nm
    merged$Friend_Correct     <- merged$Actual == merged$Friend_Predicted
    merged$Our_vs_Friend      <- merged$Our_Predicted == merged$Friend_Predicted
    merged$HV_vs_Friend       <- merged$HV_Predicted  == merged$Friend_Predicted
    merged$SV_vs_Friend       <- merged$SV_Predicted  == merged$Friend_Predicted

    compare_rows[[nm]] <- merged %>%
      select(Model, Row_id, Actual,
             Our_Predicted, Friend_Predicted,
             Our_Correct, Friend_Correct,
             Agreement_OurvsFriend = Our_vs_Friend,
             HardVote_Pred = HV_Predicted, HardVote_Correct = HV_Correct,
             SoftVote_Pred = SV_Predicted, SoftVote_Correct = SV_Correct,
             Agreement_HVvsFriend = HV_vs_Friend,
             Agreement_SVvsFriend = SV_vs_Friend)

    compare_summary[[nm]] <- data.frame(
      Model                  = nm,
      N_Rows                 = nrow(merged),
      Our_Accuracy           = round(mean(merged$Our_Correct,     na.rm=TRUE), 4),
      Friend_Accuracy        = round(mean(merged$Friend_Correct,  na.rm=TRUE), 4),
      HV_Accuracy            = round(mean(merged$HV_Correct,      na.rm=TRUE), 4),
      SV_Accuracy            = round(mean(merged$SV_Correct,      na.rm=TRUE), 4),
      OurvsFriend_Agreement  = round(mean(merged$Our_vs_Friend,   na.rm=TRUE), 4),
      HVvsFriend_Agreement   = round(mean(merged$HV_vs_Friend,    na.rm=TRUE), 4),
      SVvsFriend_Agreement   = round(mean(merged$SV_vs_Friend,    na.rm=TRUE), 4),
      stringsAsFactors = FALSE
    )

    cat(sprintf("  %-4s: Ours=%.4f Friend=%.4f HV=%.4f SV=%.4f | Agreement(Ours)=%.4f\n",
                nm,
                compare_summary[[nm]]$Our_Accuracy,
                compare_summary[[nm]]$Friend_Accuracy,
                compare_summary[[nm]]$HV_Accuracy,
                compare_summary[[nm]]$SV_Accuracy,
                compare_summary[[nm]]$OurvsFriend_Agreement))
  }

  if (length(compare_rows) > 0) {
    friend_comparison     <- bind_rows(compare_rows)
    friend_compare_summary <- bind_rows(compare_summary)
  }
}

# ── 13. Confusion Matrices (Test Set) ─────────────────────────
cat("\n=== Step G: Confusion matrices ===\n")

cm_hv <- hv_eval$cm$table
cm_sv <- sv_eval$cm$table

cm_test_all <- bind_rows(
  lapply(names(all_results), function(nm) {
    tbl <- as.data.frame(all_results[[nm]][["Test"]]$cm$table)
    tbl$Model <- nm; tbl
  }),
  {t1 <- as.data.frame(cm_hv); t1$Model <- "Ensemble_HardVote"; t1},
  {t2 <- as.data.frame(cm_sv); t2$Model <- "Ensemble_SoftVote"; t2}
)

# ── 14. Plots ─────────────────────────────────────────────────
cat("\n=== Generating plots ===\n")

all_models_for_plot <- c(names(all_results), "Ensemble_HardVote (Top3)", "Ensemble_SoftVote (Top3)")

# ── Plot A: Full comparison bar chart ──
plot_data_full <- full_comparison %>%
  select(Model, Accuracy, Macro_AUC, Macro_F1,
         Macro_Sensitivity, Macro_Specificity, Macro_Precision) %>%
  pivot_longer(-Model, names_to = "Metric", values_to = "Value") %>%
  mutate(
    IsEnsemble = grepl("Ensemble", Model),
    EnsType    = case_when(
      grepl("Hard",  Model) ~ "Hard Vote",
      grepl("Soft",  Model) ~ "Soft Vote",
      TRUE                   ~ "Single"
    ),
    Metric = factor(Metric, levels = c("Accuracy","Macro_AUC","Macro_F1",
                                        "Macro_Sensitivity","Macro_Specificity",
                                        "Macro_Precision"))
  )

p_full_bar <- ggplot(plot_data_full, aes(x = Model, y = Value, fill = EnsType)) +
  geom_col(width = 0.65) +
  geom_text(aes(label = sprintf("%.4f", Value)), vjust = -0.3, size = 2.5, fontface = "bold") +
  facet_wrap(~ Metric, scales = "free_y", ncol = 3) +
  scale_fill_manual(values = c("Single" = "#60A5FA",
                                "Hard Vote" = "#F87171",
                                "Soft Vote" = "#34D399")) +
  labs(title    = "Full Comparison: 4 Single Models + 2 Ensemble Models",
       subtitle = "Test Set | Multi-Class | Blue=Single | Red=Hard Vote | Green=Soft Vote",
       x = NULL, y = "Value", fill = NULL) +
  theme_bw(base_family = "serif", base_size =9) +
  theme(axis.text.x    = element_text(angle = 40, hjust = 1),
        plot.title      = element_text(face = "bold"),
        legend.position = "top")

ggsave(file.path(PLOT_DIR, "01_full_comparison_bar.png"),
       p_full_bar, width = 16, height = 10, dpi = 300)
cat("  Saved: 01_full_comparison_bar.png\n")

# ── Plot B: Macro-AUC ranking ──
p_auc_rank <- ggplot(full_comparison,
                     aes(x = reorder(Model, Macro_AUC), y = Macro_AUC,
                         fill = grepl("Ensemble", Model))) +
  geom_col(width = 0.6) +
  geom_text(aes(label = sprintf("%.4f (#%d)", Macro_AUC, Rank)),
            hjust = -0.1, size = 3.5, fontface = "bold") +
  scale_fill_manual(values = c("FALSE" = "#3B82F6", "TRUE" = "#EF4444"), guide = "none") +
  coord_flip() +
  ylim(0, 1.15) +
  labs(title    = "Macro-AUC Ranking — All 6 Models (Test Set)",
       subtitle = "Blue = Single Model | Red = Ensemble",
       x = NULL, y = "Macro AUC (OvR)") +
  theme_bw(base_family = "serif", base_size =12) +
  theme(plot.title = element_text(face = "bold"))

ggsave(file.path(PLOT_DIR, "02_macro_auc_ranking.png"),
       p_auc_rank, width = 11, height = 6, dpi = 300)
cat("  Saved: 02_macro_auc_ranking.png\n")

# ── Plot C: Confusion matrices — Ensemble (Hard + Soft) ──
for (ens_name in c("Ensemble_HardVote", "Ensemble_SoftVote")) {
  cm_tbl <- cm_test_all %>% filter(Model == ens_name)
  p_cm <- ggplot(cm_tbl, aes(x = Reference, y = Prediction, fill = Freq)) +
    geom_tile(colour = "white") +
    geom_text(aes(label = Freq), size = 5, fontface = "bold") +
    scale_fill_gradient(low = "#ECFDF5", high = "#065F46") +
    labs(title = paste0(ens_name, " — Confusion Matrix (Test Set)")) +
    theme_minimal(base_family = "serif", base_size =11) +
    theme(axis.text.x = element_text(angle = 30, hjust = 1),
          plot.title  = element_text(face = "bold"),
          panel.border = element_rect(colour = "black", fill = NA, linewidth = 0.8))
  ggsave(file.path(PLOT_DIR, sprintf("03_cm_%s.png", gsub("Ensemble_", "", ens_name))),
         p_cm, width = max(6, N_CLASSES*1.5), height = max(5, N_CLASSES*1.3), dpi = 300)
}
cat("  Saved: 03_cm_HardVote.png and 03_cm_SoftVote.png\n")

# ── Plot D: Per-class AUC comparison heatmap (all 6 models) ──
per_class_all_auc <- full_per_class %>%
  mutate(Model_Short = gsub(" \\(Top3\\)", "", Model)) %>%
  select(Model = Model_Short, Class, AUC)

p_full_heatmap <- ggplot(per_class_all_auc,
                          aes(x = Class, y = Model, fill = AUC)) +
  geom_tile(colour = "white", linewidth = 0.8) +
  geom_text(aes(label = sprintf("%.4f", AUC)), size = 3.5, fontface = "bold") +
  scale_fill_gradient(low = "#FEF3C7", high = "#1E3A5F",
                      na.value = "grey80", limits = c(0,1), name = "AUC") +
  labs(title    = "Per-Class AUC Heatmap — All 6 Models (Test Set)",
       subtitle = "OvR AUC per tumor class",
       x = "Tumor Class", y = NULL) +
  theme_minimal(base_family = "serif", base_size =11) +
  theme(plot.title  = element_text(face = "bold"),
        axis.text.x = element_text(angle = 30, hjust = 1),
        panel.grid  = element_blank(),
        panel.border = element_rect(colour = "black", fill = NA, linewidth = 0.8))

ggsave(file.path(PLOT_DIR, "04_per_class_auc_heatmap_all6.png"),
       p_full_heatmap, width = max(9, N_CLASSES*2.5+3), height = 7, dpi = 300)
cat("  Saved: 04_per_class_auc_heatmap_all6.png\n")

# ── Plot E: Per-class F1 heatmap (all 6 models) ──
per_class_all_f1 <- full_per_class %>%
  mutate(Model_Short = gsub(" \\(Top3\\)", "", Model)) %>%
  select(Model = Model_Short, Class, F1)

p_f1_heatmap <- ggplot(per_class_all_f1,
                        aes(x = Class, y = Model, fill = F1)) +
  geom_tile(colour = "white", linewidth = 0.8) +
  geom_text(aes(label = sprintf("%.4f", F1)), size = 3.5, fontface = "bold") +
  scale_fill_gradient(low = "#FEE2E2", high = "#166534",
                      na.value = "grey80", limits = c(0,1), name = "F1") +
  labs(title    = "Per-Class F1 Score Heatmap — All 6 Models (Test Set)",
       x = "Tumor Class", y = NULL) +
  theme_minimal(base_family = "serif", base_size =11) +
  theme(plot.title  = element_text(face = "bold"),
        axis.text.x = element_text(angle = 30, hjust = 1),
        panel.grid  = element_blank(),
        panel.border = element_rect(colour = "black", fill = NA, linewidth = 0.8))

ggsave(file.path(PLOT_DIR, "05_per_class_f1_heatmap_all6.png"),
       p_f1_heatmap, width = max(9, N_CLASSES*2.5+3), height = 7, dpi = 300)
cat("  Saved: 05_per_class_f1_heatmap_all6.png\n")

# ── Plot F: Vote agreement map (per row) ──
vote_map <- pred_wide %>%
  mutate(Row_idx = seq_len(nrow(pred_wide))) %>%
  select(Row_idx, Actual,
         HardVote_Correct, SoftVote_Correct, N_SingleModels_Correct) %>%
  pivot_longer(cols = c(HardVote_Correct, SoftVote_Correct),
               names_to = "Ensemble", values_to = "Correct") %>%
  mutate(Ensemble = gsub("_Correct", "", Ensemble))

p_vote_acc <- ggplot(vote_map, aes(x = N_SingleModels_Correct, fill = Correct)) +
  geom_bar(position = "fill", width = 0.7) +
  facet_wrap(~ Ensemble) +
  scale_fill_manual(values = c("TRUE" = "#22C55E", "FALSE" = "#EF4444")) +
  scale_x_continuous(breaks = 0:4) +
  labs(title    = "Ensemble Accuracy by Number of Correct Single Models",
       subtitle = "When more single models agree, does ensemble perform better?",
       x = "# Single Models Correct (out of 4)",
       y = "Proportion", fill = "Ensemble Correct") +
  theme_bw(base_family = "serif", base_size =11) +
  theme(plot.title = element_text(face = "bold"))

ggsave(file.path(PLOT_DIR, "06_ensemble_accuracy_by_agreement.png"),
       p_vote_acc, width = 12, height = 5, dpi = 300)
cat("  Saved: 06_ensemble_accuracy_by_agreement.png\n")

# ── Plot G: Model comparison all metrics (spider / radar style via facets) ──
radar_data <- full_comparison %>%
  select(Model, Accuracy, Macro_AUC, Macro_F1,
         Macro_Sensitivity, Macro_Specificity, Macro_Precision) %>%
  pivot_longer(-Model, names_to = "Metric", values_to = "Value") %>%
  mutate(IsEnsemble = grepl("Ensemble", Model))

p_radar_bar <- ggplot(radar_data, aes(x = Metric, y = Value, fill = IsEnsemble)) +
  geom_col(width = 0.65) +
  geom_text(aes(label = sprintf("%.3f", Value)), vjust = -0.3, size = 2.2) +
  facet_wrap(~ Model, ncol = 3) +
  scale_fill_manual(values = c("FALSE" = "#93C5FD", "TRUE" = "#FCA5A5"), guide = "none") +
  ylim(0, 1.1) +
  labs(title = "Performance Profile — All 6 Models (Test Set)",
       x = NULL, y = "Value") +
  theme_bw(base_family = "serif", base_size =9) +
  theme(axis.text.x  = element_text(angle = 40, hjust = 1),
        plot.title    = element_text(face = "bold"),
        strip.text    = element_text(face = "bold"))

ggsave(file.path(PLOT_DIR, "07_performance_profile_all6.png"),
       p_radar_bar, width = 16, height = 10, dpi = 300)
cat("  Saved: 07_performance_profile_all6.png\n")

# ── Plot H: ROC curves overlay (OvR, Test Set) ──
cat("  Building OvR ROC curves for all 6 models...\n")
all_model_preds_for_roc <- c(
  lapply(names(all_results), function(nm) {
    list(model_name = nm,
         pred_class = all_results[[nm]][["Test"]]$pred_class,
         prob_mat   = all_results[[nm]][["Test"]]$prob_mat)
  }),
  list(
    list(model_name = "Ensemble_HardVote", pred_class = hard_vote_class, prob_mat = hard_vote_prob),
    list(model_name = "Ensemble_SoftVote", pred_class = soft_vote_class, prob_mat = soft_vote_prob)
  )
)

roc_curve_df <- bind_rows(lapply(all_model_preds_for_roc, function(r) {
  bind_rows(lapply(CLASS_LEVELS, function(cls) {
    bin <- as.numeric(y_test == cls)
    if (length(unique(bin)) < 2) return(NULL)
    prob_col <- if (cls %in% colnames(r$prob_mat)) r$prob_mat[, cls] else
      as.numeric(r$pred_class == cls)
    roc_obj <- tryCatch(pROC::roc(bin, prob_col, quiet = TRUE), error = function(e) NULL)
    if (is.null(roc_obj)) return(NULL)
    data.frame(
      Model  = r$model_name,
      Class  = cls,
      FPR    = 1 - roc_obj$specificities,
      TPR    = roc_obj$sensitivities,
      AUC    = round(as.numeric(pROC::auc(roc_obj)), 4),
      stringsAsFactors = FALSE
    )
  }))
}))

p_roc <- ggplot(roc_curve_df, aes(x = FPR, y = TPR, color = Model)) +
  geom_line(linewidth = 0.8) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey60") +
  facet_wrap(~ Class, ncol = min(3, N_CLASSES)) +
  scale_color_brewer(palette = "Dark2") +
  labs(title    = "OvR ROC Curves — All 6 Models (Test Set)",
       subtitle = "One curve per model per class",
       x = "False Positive Rate (1 - Specificity)",
       y = "True Positive Rate (Sensitivity)",
       color = NULL) +
  theme_bw(base_family = "serif", base_size =10) +
  theme(plot.title      = element_text(face = "bold"),
        legend.position = "bottom")

ggsave(file.path(PLOT_DIR, "08_roc_curves_all6_models.png"),
       p_roc, width = max(12, N_CLASSES * 5), height = 6, dpi = 300)
cat("  Saved: 08_roc_curves_all6_models.png\n")

# ── 15. Save Results to xlsx ──────────────────────────────────
cat("\n=== Saving to xlsx ===\n")

header_style <- createStyle(fontColour = "#FFFFFF", fgFill = "#065F46",
                             halign = "CENTER", textDecoration = "bold",
                             border = "Bottom", borderStyle = "medium")
ens_header   <- createStyle(fontColour = "#FFFFFF", fgFill = "#7C3AED",
                             halign = "CENTER", textDecoration = "bold",
                             border = "Bottom", borderStyle = "medium")

wb <- createWorkbook()

# ── README ──
addWorksheet(wb, "README")
readme <- data.frame(
  Section = c(
    "Script", "Created", "Purpose",
    "── SINGLE MODEL SHEETS ──",
    "Single_Model_Ranking",
    "Single_Overall_Metrics",
    "Single_PerClass_Metrics",
    "── ENSEMBLE SHEETS ──",
    "Ensemble_Config",
    "HardVote_Metrics",
    "SoftVote_Metrics",
    "Full_Comparison_All6",
    "Full_PerClass_All6",
    "Soft_Vote_Probabilities",
    "── PREDICTION SHEETS ──",
    "All6_Predictions",
    "RowRow_Wide_Comparison",
    "── FRIEND COMPARISON SHEETS ──",
    "Friend_Comparison_Detail",
    "Friend_Comparison_Summary",
    "── DATA SHEETS ──",
    "CM_All_Models"
  ),
  Description = c(
    "02_ensemble_multi.R",
    as.character(Sys.time()),
    "Ensemble (Hard + Soft Vote) using top-3 models; full 6-model comparison",
    "",
    "4 single models ranked by test Macro-AUC; shows top-3 selection",
    "Overall metrics for 4 single models (test set)",
    "Per-class metrics for 4 single models (test set)",
    "",
    paste0("Top-3: ", paste(top3_names, collapse=" > "), " | Best: ", best_model_name),
    "Hard Vote Ensemble — overall metrics on test set",
    "Soft Vote Ensemble — overall metrics on test set",
    "All 6 models compared side-by-side (4 single + 2 ensemble) sorted by Macro-AUC",
    "Per-class metrics for all 6 models",
    "Soft Vote probability table per row (all class probabilities)",
    "",
    "All 6 models — row-level predictions on test set (with probabilities)",
    "Wide table: each row = one test sample; columns = predictions from each model",
    "",
    "Row-by-row: our predictions + ensemble predictions vs friend's xlsx",
    "Summary statistics of agreement per model",
    "",
    "Confusion matrix tables for all 6 models (test set)"
  ), stringsAsFactors = FALSE
)
writeData(wb, "README", readme)
setColWidths(wb, "README", cols = 1:2, widths = c(35, 80))

# ── Single model ranking ──
addWorksheet(wb, "Single_Model_Ranking")
writeData(wb, "Single_Model_Ranking", test_eval, headerStyle = header_style)
setColWidths(wb, "Single_Model_Ranking", cols = 1:ncol(test_eval), widths = "auto")

# ── Single model overall metrics ──
addWorksheet(wb, "Single_Overall_Metrics")
writeData(wb, "Single_Overall_Metrics",
          overall_metrics %>% filter(Set == "Test"), headerStyle = header_style)
setColWidths(wb, "Single_Overall_Metrics", cols = 1:ncol(overall_metrics)-1, widths = "auto")

# ── Single model per-class metrics ──
addWorksheet(wb, "Single_PerClass_Metrics")
writeData(wb, "Single_PerClass_Metrics",
          per_class_metrics %>% filter(Set == "Test"), headerStyle = header_style)
setColWidths(wb, "Single_PerClass_Metrics", cols = 1:ncol(per_class_metrics)-1, widths = "auto")

# ── Ensemble config ──
addWorksheet(wb, "Ensemble_Config")
ens_config <- data.frame(
  Parameter = c("Ensemble type", "Number of base models",
                "Top-1 (Best)", "Top-2", "Top-3",
                "Tie-break model",
                "Hard Vote strategy",
                "Soft Vote strategy",
                "Test set size",
                paste0("Class_", seq_along(CLASS_LEVELS))),
  Value = c("Hard Vote + Soft Vote",
            as.character(length(top3_names)),
            top3_names[1], top3_names[2], top3_names[3],
            best_model_name,
            "Majority of 3 class votes; ties broken by best model's prediction",
            "Average probability across top-3 models; argmax for final class",
            as.character(nrow(test_set)),
            CLASS_LEVELS),
  stringsAsFactors = FALSE
)
writeData(wb, "Ensemble_Config", ens_config, headerStyle = ens_header)
setColWidths(wb, "Ensemble_Config", cols = 1:2, widths = c(30, 60))

# ── Ensemble metrics ──
addWorksheet(wb, "HardVote_Metrics")
writeData(wb, "HardVote_Metrics", hv_eval$metrics, headerStyle = ens_header)
setColWidths(wb, "HardVote_Metrics", cols = 1:ncol(hv_eval$metrics), widths = "auto")

addWorksheet(wb, "HardVote_PerClass")
writeData(wb, "HardVote_PerClass", hv_per_class, headerStyle = ens_header)
setColWidths(wb, "HardVote_PerClass", cols = 1:ncol(hv_per_class), widths = "auto")

addWorksheet(wb, "SoftVote_Metrics")
writeData(wb, "SoftVote_Metrics", sv_eval$metrics, headerStyle = ens_header)
setColWidths(wb, "SoftVote_Metrics", cols = 1:ncol(sv_eval$metrics), widths = "auto")

addWorksheet(wb, "SoftVote_PerClass")
writeData(wb, "SoftVote_PerClass", sv_per_class, headerStyle = ens_header)
setColWidths(wb, "SoftVote_PerClass", cols = 1:ncol(sv_per_class), widths = "auto")

# ── Full comparison (all 6 models) ──
addWorksheet(wb, "Full_Comparison_All6")
writeData(wb, "Full_Comparison_All6", full_comparison, headerStyle = header_style)
setColWidths(wb, "Full_Comparison_All6", cols = 1:ncol(full_comparison), widths = "auto")
conditionalFormatting(wb, "Full_Comparison_All6",
                       cols = which(names(full_comparison) == "Macro_AUC"),
                       rows = 2:(nrow(full_comparison)+1),
                       type = "databar", style = c("#A7F3D0", "#065F46"))

addWorksheet(wb, "Full_PerClass_All6")
writeData(wb, "Full_PerClass_All6", full_per_class, headerStyle = header_style)
setColWidths(wb, "Full_PerClass_All6", cols = 1:ncol(full_per_class), widths = "auto")

# ── Soft vote probabilities ──
addWorksheet(wb, "Soft_Vote_Probabilities")
writeData(wb, "Soft_Vote_Probabilities", sv_prob_df, headerStyle = ens_header)
setColWidths(wb, "Soft_Vote_Probabilities", cols = 1:ncol(sv_prob_df), widths = "auto")

# ── All predictions (all 6 models, test set) ──
addWorksheet(wb, "All6_Predictions")
writeData(wb, "All6_Predictions", all_6_preds, headerStyle = header_style)
setColWidths(wb, "All6_Predictions", cols = 1:ncol(all_6_preds), widths = "auto")

# ── Wide row-by-row comparison ──
addWorksheet(wb, "RowRow_Wide_Comparison")
writeData(wb, "RowRow_Wide_Comparison", pred_wide, headerStyle = header_style)
setColWidths(wb, "RowRow_Wide_Comparison", cols = 1:ncol(pred_wide), widths = "auto")

# ── Friend comparison sheets ──
if (nrow(friend_comparison) > 0) {
  addWorksheet(wb, "Friend_Comparison_Detail")
  writeData(wb, "Friend_Comparison_Detail", friend_comparison, headerStyle = header_style)
  setColWidths(wb, "Friend_Comparison_Detail", cols = 1:ncol(friend_comparison), widths = "auto")
}

if (nrow(friend_compare_summary) > 0) {
  addWorksheet(wb, "Friend_Comparison_Summary")
  writeData(wb, "Friend_Comparison_Summary", friend_compare_summary, headerStyle = header_style)
  setColWidths(wb, "Friend_Comparison_Summary", cols = 1:ncol(friend_compare_summary), widths = "auto")
}

# ── Confusion matrices ──
addWorksheet(wb, "CM_All_Models")
writeData(wb, "CM_All_Models", cm_test_all, headerStyle = header_style)
setColWidths(wb, "CM_All_Models", cols = 1:ncol(cm_test_all), widths = "auto")

# Save
xlsx_path <- file.path(OUT_DIR, "ensemble_results.xlsx")
saveWorkbook(wb, xlsx_path, overwrite = TRUE)
cat(sprintf("  Saved: %s\n", xlsx_path))

# ── 16. Save RDS ──────────────────────────────────────────────
rds_path <- file.path(OUT_DIR, "ensemble_model.rds")
saveRDS(list(
  top3_names          = top3_names,
  best_model_name     = best_model_name,
  CLASS_LEVELS        = CLASS_LEVELS,
  N_CLASSES           = N_CLASSES,
  hard_vote_class     = hard_vote_class,
  hard_vote_prob      = hard_vote_prob,
  soft_vote_class     = soft_vote_class,
  soft_vote_prob      = soft_vote_prob,
  hv_metrics          = hv_eval$metrics,
  sv_metrics          = sv_eval$metrics,
  hv_per_class        = hv_per_class,
  sv_per_class        = sv_per_class,
  full_comparison     = full_comparison,
  full_per_class      = full_per_class,
  pred_wide           = pred_wide,
  all_6_preds         = all_6_preds,
  friend_comparison   = friend_comparison,
  friend_compare_summary = friend_compare_summary
), rds_path)
cat(sprintf("  Saved: %s\n", rds_path))

# ── 17. Print Final Summary ───────────────────────────────────
cat("\n╔══════════════════════════════════════════════════════════════╗\n")
cat("║  ENSEMBLE RESULTS SUMMARY                                     ║\n")
cat("╚══════════════════════════════════════════════════════════════╝\n")
cat(sprintf("\n  Classes     : %s\n", paste(CLASS_LEVELS, collapse=", ")))
cat(sprintf("  Test rows   : %d\n\n", nrow(test_set)))
cat(sprintf("  Top-3 selection  : %-4s > %-4s > %-4s (by Macro-AUC)\n",
            top3_names[1], top3_names[2], top3_names[3]))
cat(sprintf("  Tie-break model  : %s\n\n", best_model_name))

cat("  ── Single Models (Test) ──────────────────────────────────\n")
print(test_eval %>% select(Rank, Model, Accuracy, Macro_AUC, Macro_F1) %>% as.data.frame(),
      row.names = FALSE)

cat("\n  ── Ensemble Models (Test) ────────────────────────────────\n")
cat(sprintf("  Hard Vote   Accuracy=%.4f  Macro-AUC=%.4f  Macro-F1=%.4f\n",
            hv_eval$metrics$Accuracy, hv_eval$metrics$Macro_AUC, hv_eval$metrics$Macro_F1))
cat(sprintf("  Soft Vote   Accuracy=%.4f  Macro-AUC=%.4f  Macro-F1=%.4f\n",
            sv_eval$metrics$Accuracy, sv_eval$metrics$Macro_AUC, sv_eval$metrics$Macro_F1))

cat("\n  ── Best Model Overall ────────────────────────────────────\n")
best_row <- full_comparison[1, ]
cat(sprintf("  %s  Accuracy=%.4f  Macro-AUC=%.4f  Macro-F1=%.4f\n",
            best_row$Model, best_row$Accuracy, best_row$Macro_AUC, best_row$Macro_F1))

cat(sprintf("\n  Output: %s\n", OUT_DIR))
cat("╚══════════════════════════════════════════════════════════════╝\n")
