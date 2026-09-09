# ============================================================
#  MULTI-CLASS ENSEMBLE — STEP 1: SINGLE MODEL ANALYSIS
#
#  วัตถุประสงค์:
#    1) โหลด 4 pre-trained models (KNN, SVM, XGB, RF)
#    2) Predict บน train/val/test splits ของเพื่อน (ใช้ splits เดิม)
#    3) คำนวณ metrics แบบละเอียด (overall + per-class, ทุก set)
#    4) โหลด xlsx predictions ของเพื่อน
#    5) เปรียบเทียบ prediction ของเรา vs เพื่อน row-by-row
#    6) บันทึกผลลัพธ์ (xlsx หลายชีต + plots)
#
#  Inputs:
#    model/multi/*.rds
#    data/ML_multi_{train,val,test}.rds
#    data/reference/ML_predictions_multi.xlsx
#
#  Outputs:
#    results/01_single_model/single_model_analysis.xlsx
#    results/01_single_model/plots/*.png
#    results/01_single_model/step1_results.rds  (used by step 2)
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

set.seed(123)

cat("╔══════════════════════════════════════════════════════╗\n")
cat("║  STEP 1: SINGLE MODEL ANALYSIS — MULTI-CLASS         ║\n")
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

OUT_DIR <- STEP1_DIR
PLOT_DIR     <- file.path(OUT_DIR, "plots")

dir.create(PLOT_DIR, recursive = TRUE, showWarnings = FALSE)

cat("── Paths ──\n")
cat("  Model dir :", MODEL_DIR, "\n")
cat("  Data  dir :", DF_DIR, "\n")
cat("  Output dir:", OUT_DIR, "\n\n")

# ── 2. Load Data ─────────────────────────────────────────────
cat("=== Loading datasets (friend's splits) ===\n")

train_set <- readRDS(file.path(DF_DIR, "ML_multi_train.rds"))
val_set   <- readRDS(file.path(DF_DIR, "ML_multi_val.rds"))
test_set  <- readRDS(file.path(DF_DIR, "ML_multi_test.rds"))

# Normalise tumor_type to factor with consistent levels across all sets
all_types    <- sort(unique(c(
  as.character(train_set$tumor_type),
  as.character(val_set$tumor_type),
  as.character(test_set$tumor_type)
)))
CLASS_LEVELS <- all_types
N_CLASSES    <- length(CLASS_LEVELS)

train_set$tumor_type <- factor(train_set$tumor_type, levels = CLASS_LEVELS)
val_set$tumor_type   <- factor(val_set$tumor_type,   levels = CLASS_LEVELS)
test_set$tumor_type  <- factor(test_set$tumor_type,  levels = CLASS_LEVELS)

cat(sprintf("Classes (%d): %s\n", N_CLASSES, paste(CLASS_LEVELS, collapse = ", ")))
cat(sprintf("Train: %d rows | Val: %d rows | Test: %d rows\n\n",
            nrow(train_set), nrow(val_set), nrow(test_set)))

cat("── Distribution per set ──\n")
cat("Train:\n");      print(table(train_set$tumor_type))
cat("Validation:\n"); print(table(val_set$tumor_type))
cat("Test:\n");       print(table(test_set$tumor_type))

# ── 3. Load Pre-trained Models ───────────────────────────────
cat("\n=== Loading pre-trained models ===\n")
models <- list(
  KNN = readRDS(file.path(MODEL_DIR, "knn_tune_model_multi_seed.rds")),
  SVM = readRDS(file.path(MODEL_DIR, "svm_tune_model_multi_seed.rds")),
  XGB = readRDS(file.path(MODEL_DIR, "xgb_tune_model_multi_seed.rds")),
  RF  = readRDS(file.path(MODEL_DIR, "rf_tune_model_multi_seed.rds"))
)
for (nm in names(models)) {
  cat(sprintf("  %-4s : %s\n", nm, paste(class(models[[nm]]), collapse = "/")))
}

# ── 4. Helper Functions ───────────────────────────────────────

# Compute macro-AUC (OvR mean)
compute_macro_auc <- function(y_true, prob_mat, class_lvls) {
  auc_vals <- sapply(class_lvls, function(cls) {
    bin <- as.numeric(y_true == cls)
    if (length(unique(bin)) < 2) return(NA_real_)
    col <- if (cls %in% colnames(prob_mat)) prob_mat[, cls] else prob_mat[, which(class_lvls == cls)]
    tryCatch(as.numeric(pROC::auc(pROC::roc(bin, col, quiet = TRUE))), error = function(e) NA_real_)
  })
  mean(auc_vals, na.rm = TRUE)
}

# Compute per-class AUC (OvR)
compute_per_class_auc <- function(y_true, prob_mat, class_lvls) {
  setNames(sapply(class_lvls, function(cls) {
    bin <- as.numeric(y_true == cls)
    if (length(unique(bin)) < 2) return(NA_real_)
    col <- if (cls %in% colnames(prob_mat)) prob_mat[, cls] else NA_real_
    if (all(is.na(col))) return(NA_real_)
    tryCatch(as.numeric(pROC::auc(pROC::roc(bin, col, quiet = TRUE))), error = function(e) NA_real_)
  }), class_lvls)
}

# Evaluate one model on one dataset split
evaluate_on_set <- function(model, dataset, class_lvls, set_name, model_name) {

  dataset$tumor_type <- factor(dataset$tumor_type, levels = class_lvls)
  y_true <- dataset$tumor_type

  pred_class <- factor(predict(model, newdata = dataset), levels = class_lvls)

  prob_mat <- tryCatch({
    p <- as.matrix(predict(model, newdata = dataset, type = "prob"))
    if (!is.null(colnames(p)) && all(class_lvls %in% colnames(p))) {
      p[, class_lvls, drop = FALSE]
    } else {
      if (!is.null(colnames(p)) && ncol(p) == length(class_lvls)) colnames(p) <- class_lvls
      p
    }
  }, error = function(e) {
    cat(sprintf("    [WARN] prob prediction failed for %s/%s: %s\n", model_name, set_name, e$message))
    mat <- matrix(0, nrow = nrow(dataset), ncol = length(class_lvls),
                  dimnames = list(NULL, class_lvls))
    for (i in seq_along(pred_class)) mat[i, as.character(pred_class[i])] <- 1
    mat
  })

  cm         <- confusionMatrix(pred_class, y_true)
  macro_auc  <- compute_macro_auc(y_true, prob_mat, class_lvls)
  cls_aucs   <- compute_per_class_auc(y_true, prob_mat, class_lvls)

  # ── Overall metrics table ──
  overall <- data.frame(
    Model             = model_name,
    Set               = set_name,
    Accuracy          = round(as.numeric(cm$overall["Accuracy"]),      4),
    Kappa             = round(as.numeric(cm$overall["Kappa"]),          4),
    AccuracyLower95   = round(as.numeric(cm$overall["AccuracyLower"]), 4),
    AccuracyUpper95   = round(as.numeric(cm$overall["AccuracyUpper"]), 4),
    Macro_AUC         = round(macro_auc,                                4),
    Macro_Sensitivity = round(mean(cm$byClass[, "Sensitivity"],   na.rm = TRUE), 4),
    Macro_Specificity = round(mean(cm$byClass[, "Specificity"],   na.rm = TRUE), 4),
    Macro_Precision   = round(mean(cm$byClass[, "Pos Pred Value"], na.rm = TRUE), 4),
    Macro_F1          = round(mean(cm$byClass[, "F1"],             na.rm = TRUE), 4),
    stringsAsFactors  = FALSE
  )

  # ── Per-class metrics table ──
  by_cls <- as.data.frame(cm$byClass)
  by_cls$Class <- gsub("^Class: ", "", rownames(by_cls))
  by_cls$Model <- model_name
  by_cls$Set   <- set_name
  by_cls$AUC   <- cls_aucs[by_cls$Class]
  rownames(by_cls) <- NULL
  by_cls <- by_cls %>%
    select(Model, Set, Class,
           Sensitivity, Specificity,
           Precision = `Pos Pred Value`,
           NPV = `Neg Pred Value`,
           F1, AUC) %>%
    mutate(across(where(is.numeric), ~ round(.x, 4)))

  # ── Row-level predictions table ──
  row_id_col <- if ("row_id" %in% names(dataset)) dataset$row_id else seq_len(nrow(dataset))
  pred_rows  <- data.frame(
    Model     = model_name,
    Set       = set_name,
    Row_id    = row_id_col,
    Actual    = as.character(y_true),
    Predicted = as.character(pred_class),
    Correct   = as.character(y_true) == as.character(pred_class),
    stringsAsFactors = FALSE
  )
  prob_cols            <- as.data.frame(prob_mat)
  colnames(prob_cols)  <- paste0("Prob_", class_lvls)
  pred_rows            <- cbind(pred_rows, round(prob_cols, 6))

  list(
    overall    = overall,
    by_class   = by_cls,
    pred_rows  = pred_rows,
    cm         = cm,
    prob_mat   = prob_mat,
    pred_class = pred_class,
    y_true     = y_true
  )
}

# ── 5. Run Evaluation: All 4 Models × 3 Sets ─────────────────
cat("\n=== Evaluating 4 models × 3 sets ===\n")
sets_list <- list(Train = train_set, Validation = val_set, Test = test_set)

all_results <- list()
for (nm in names(models)) {
  cat(sprintf("\n─── Model: %-4s ────────────────────\n", nm))
  model_res <- list()
  for (sn in names(sets_list)) {
    cat(sprintf("  Set: %-12s ... ", sn))
    model_res[[sn]] <- evaluate_on_set(models[[nm]], sets_list[[sn]], CLASS_LEVELS, sn, nm)
    cat(sprintf("Accuracy = %.4f | Macro-AUC = %.4f\n",
                model_res[[sn]]$overall$Accuracy,
                model_res[[sn]]$overall$Macro_AUC))
  }
  all_results[[nm]] <- model_res
}

# ── 6. Compile Summary Tables ────────────────────────────────
cat("\n=== Compiling summary tables ===\n")

overall_metrics <- bind_rows(lapply(names(all_results), function(nm)
  bind_rows(lapply(names(all_results[[nm]]), function(sn)
    all_results[[nm]][[sn]]$overall
  ))
))

per_class_metrics <- bind_rows(lapply(names(all_results), function(nm)
  bind_rows(lapply(names(all_results[[nm]]), function(sn)
    all_results[[nm]][[sn]]$by_class
  ))
))

all_predictions <- bind_rows(lapply(names(all_results), function(nm)
  bind_rows(lapply(names(all_results[[nm]]), function(sn)
    all_results[[nm]][[sn]]$pred_rows
  ))
))

cat("\n══ Test Set — Overall Metrics ══\n")
print(overall_metrics %>% filter(Set == "Test") %>%
        select(Model, Accuracy, Macro_AUC, Macro_F1, Macro_Sensitivity, Macro_Specificity))

# ── 7. Load Friend's xlsx Predictions ────────────────────────
cat("\n=== Loading friend's xlsx predictions ===\n")
friend_xlsx <- file.path(FRIEND_RESULT_DIR, "ML_predictions_multi.xlsx")
friend_preds_all <- NULL
friend_preds_by_model <- list()

if (file.exists(friend_xlsx)) {
  sheet_names <- getSheetNames(friend_xlsx)
  cat("  Sheets:", paste(sheet_names, collapse = ", "), "\n")

  for (sh in sheet_names) {
    df <- tryCatch(read.xlsx(friend_xlsx, sheet = sh), error = function(e) NULL)
    if (!is.null(df)) {
      df$Sheet <- sh
      friend_preds_by_model[[sh]] <- df
    }
  }
  friend_preds_all <- bind_rows(friend_preds_by_model)
  cat(sprintf("  Total rows loaded: %d | Columns: %s\n",
              nrow(friend_preds_all),
              paste(names(friend_preds_all), collapse = ", ")))
} else {
  cat("  WARNING: friend xlsx not found at", friend_xlsx, "\n")
}

# ── 8. Row-by-Row Comparison: Our Predictions vs Friend's ────
cat("\n=== Row-by-row comparison: Our predictions vs Friend's xlsx ===\n")

comparison_list  <- list()
agreement_summary <- list()

if (!is.null(friend_preds_all) && nrow(friend_preds_all) > 0) {

  # Auto-detect column names (case-insensitive)
  detect_col <- function(df, patterns) {
    hits <- names(df)[grepl(paste(patterns, collapse = "|"), names(df), ignore.case = TRUE)]
    if (length(hits) > 0) hits[1] else NA_character_
  }

  friend_rowid_col  <- detect_col(friend_preds_all, c("row_id", "rowid", "row.id"))
  friend_pred_col   <- detect_col(friend_preds_all, c("predicted", "prediction", "pred_class"))
  friend_actual_col <- detect_col(friend_preds_all, c("actual", "true_label", "true"))
  friend_set_col    <- detect_col(friend_preds_all, c("^set$", "dataset", "split"))
  friend_model_col  <- detect_col(friend_preds_all, c("^model$", "model_name"))

  cat(sprintf("  Detected columns — row_id: '%s' | predicted: '%s' | actual: '%s'\n",
              friend_rowid_col, friend_pred_col, friend_actual_col))

  for (nm in names(models)) {

    # Get our test predictions for this model
    our_test <- all_predictions %>%
      filter(Model == nm, Set == "Test") %>%
      select(Row_id, Actual, Our_Predicted = Predicted, Our_Correct = Correct,
             starts_with("Prob_"))

    # Get friend's test predictions for this model
    friend_model <- friend_preds_all
    if (!is.na(friend_model_col) && !is.na(friend_model_col)) {
      friend_match <- friend_preds_all %>%
        filter(grepl(nm, .[[friend_model_col]], ignore.case = TRUE))
      if (nrow(friend_match) > 0) friend_model <- friend_match
    } else if (nm %in% names(friend_preds_by_model)) {
      friend_model <- friend_preds_by_model[[nm]]
    }

    # Filter to Test set if possible
    if (!is.na(friend_set_col)) {
      friend_test <- friend_model %>%
        filter(grepl("test", .[[friend_set_col]], ignore.case = TRUE))
      if (nrow(friend_test) == 0) friend_test <- friend_model
    } else {
      friend_test <- friend_model
    }

    if (nrow(friend_test) == 0 || is.na(friend_rowid_col) || is.na(friend_pred_col)) {
      cat(sprintf("  [SKIP] %s — cannot match friend predictions\n", nm))
      next
    }

    friend_sub <- friend_test %>%
      select(Row_id    = all_of(friend_rowid_col),
             Friend_Predicted = all_of(friend_pred_col))

    if (!is.na(friend_actual_col)) {
      friend_sub$Friend_Actual <- friend_test[[friend_actual_col]]
    }

    # Add friend probability columns if available
    prob_pattern <- paste0("(", paste(CLASS_LEVELS, collapse="|"), ")")
    friend_prob_cols <- names(friend_test)[grepl(prob_pattern, names(friend_test), ignore.case=TRUE) &
                                             !grepl("actual|predicted|model|set|row|sheet|type|subtype",
                                                    names(friend_test), ignore.case=TRUE)]
    if (length(friend_prob_cols) > 0) {
      friend_sub <- cbind(friend_sub,
                          setNames(friend_test[, friend_prob_cols, drop=FALSE],
                                   paste0("Friend_Prob_", friend_prob_cols)))
    }

    # Merge by Row_id
    merged <- merge(our_test, friend_sub, by = "Row_id", all.x = TRUE)

    # Ensure types match for comparison
    merged$Friend_Predicted <- as.character(merged$Friend_Predicted)
    merged$Our_Predicted    <- as.character(merged$Our_Predicted)

    merged$Model              <- nm
    merged$Friend_Correct     <- merged$Actual == merged$Friend_Predicted
    merged$Prediction_Agree   <- merged$Our_Predicted == merged$Friend_Predicted
    merged$Both_Correct       <- merged$Our_Correct & merged$Friend_Correct
    merged$Only_Our_Correct   <- merged$Our_Correct & !merged$Friend_Correct
    merged$Only_Friend_Correct <- !merged$Our_Correct & merged$Friend_Correct
    merged$Both_Wrong         <- !merged$Our_Correct & !merged$Friend_Correct

    comparison_list[[nm]] <- merged %>%
      select(Model, Row_id, Actual, Our_Predicted, Friend_Predicted,
             Our_Correct, Friend_Correct, Prediction_Agree,
             Both_Correct, Only_Our_Correct, Only_Friend_Correct, Both_Wrong,
             everything())

    n_agree <- sum(merged$Prediction_Agree, na.rm = TRUE)
    n_total <- nrow(merged)
    cat(sprintf("  %-4s Test: %d rows | Agreement: %d/%d (%.1f%%) | Our Acc: %.4f | Friend Acc: %.4f\n",
                nm, n_total, n_agree, n_total, 100 * n_agree / n_total,
                mean(merged$Our_Correct, na.rm = TRUE),
                mean(merged$Friend_Correct, na.rm = TRUE)))

    # Agreement summary per model
    agreement_summary[[nm]] <- data.frame(
      Model               = nm,
      N_Test_Rows         = n_total,
      Our_Accuracy        = round(mean(merged$Our_Correct,     na.rm = TRUE), 4),
      Friend_Accuracy     = round(mean(merged$Friend_Correct,  na.rm = TRUE), 4),
      Agreement_Rate      = round(mean(merged$Prediction_Agree, na.rm = TRUE), 4),
      N_Agreement         = n_agree,
      N_Both_Correct      = sum(merged$Both_Correct,        na.rm = TRUE),
      N_Only_Ours_Correct = sum(merged$Only_Our_Correct,    na.rm = TRUE),
      N_Only_Friend_Correct = sum(merged$Only_Friend_Correct, na.rm = TRUE),
      N_Both_Wrong        = sum(merged$Both_Wrong,          na.rm = TRUE),
      stringsAsFactors    = FALSE
    )
  }

  if (length(agreement_summary) > 0) {
    agreement_df <- bind_rows(agreement_summary)
    cat("\n══ Agreement Summary (Test Set) ══\n")
    print(agreement_df)
  } else {
    agreement_df <- data.frame()
  }
  comparison_all <- bind_rows(comparison_list)

} else {
  cat("  Skipping comparison (friend xlsx unavailable)\n")
  comparison_all <- data.frame()
  agreement_df   <- data.frame()
}

# ── 9. Confusion Matrix Tables (Test Set) ────────────────────
cm_test_tables <- bind_rows(lapply(names(all_results), function(nm) {
  tbl <- as.data.frame(all_results[[nm]][["Test"]]$cm$table)
  tbl$Model <- nm
  tbl
}))

# ── 10. Plots ─────────────────────────────────────────────────
cat("\n=== Generating plots ===\n")

# ── Plot A: Overall metrics bar chart (Test Set) ──
test_metrics_long <- overall_metrics %>%
  filter(Set == "Test") %>%
  select(Model, Accuracy, Macro_AUC, Macro_F1,
         Macro_Sensitivity, Macro_Specificity, Macro_Precision) %>%
  pivot_longer(-Model, names_to = "Metric", values_to = "Value") %>%
  mutate(Metric = factor(Metric, levels = c("Accuracy", "Macro_AUC", "Macro_F1",
                                             "Macro_Sensitivity", "Macro_Specificity",
                                             "Macro_Precision")))

p_overall <- ggplot(test_metrics_long, aes(x = Model, y = Value, fill = Model)) +
  geom_col(width = 0.65) +
  geom_text(aes(label = sprintf("%.4f", Value)), vjust = -0.35, size = 2.8, fontface = "bold") +
  facet_wrap(~ Metric, scales = "free_y", ncol = 3) +
  scale_fill_brewer(palette = "Set2") +
  scale_y_continuous(labels = number_format(accuracy = 0.001)) +
  labs(title    = "Single Model Performance — Test Set (Multi-Class)",
       subtitle  = sprintf("Classes: %s", paste(CLASS_LEVELS, collapse = " | ")),
       x = NULL, y = "Value") +
  theme_bw(base_family = "serif", base_size =10) +
  theme(axis.text.x   = element_text(angle = 30, hjust = 1),
        plot.title     = element_text(face = "bold"),
        legend.position = "none")

ggsave(file.path(PLOT_DIR, "01_overall_metrics_testset.png"),
       p_overall, width = 14, height = 8, dpi = 300)
cat("  Saved: 01_overall_metrics_testset.png\n")

# ── Plot B: Metrics across Train/Val/Test ──
acc_trend <- overall_metrics %>%
  mutate(Set = factor(Set, levels = c("Train", "Validation", "Test")))

p_acc <- ggplot(acc_trend, aes(x = Set, y = Accuracy, group = Model, color = Model)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  geom_text(aes(label = sprintf("%.4f", Accuracy)), vjust = -0.6, size = 2.8) +
  scale_color_brewer(palette = "Set1") +
  ylim(0, 1.05) +
  labs(title    = "Accuracy Trend: Train → Validation → Test",
       subtitle = "All 4 Models",
       x = "Dataset", y = "Accuracy") +
  theme_bw(base_family = "serif", base_size =11) +
  theme(plot.title = element_text(face = "bold"))

p_auc <- ggplot(acc_trend, aes(x = Set, y = Macro_AUC, group = Model, color = Model)) +
  geom_line(linewidth = 1.2) +
  geom_point(size = 3) +
  geom_text(aes(label = sprintf("%.4f", Macro_AUC)), vjust = -0.6, size = 2.8) +
  scale_color_brewer(palette = "Set1") +
  ylim(0, 1.05) +
  labs(title    = "Macro-AUC Trend: Train → Validation → Test",
       subtitle = "All 4 Models",
       x = "Dataset", y = "Macro AUC (OvR)") +
  theme_bw(base_family = "serif", base_size =11) +
  theme(plot.title = element_text(face = "bold"))

combined_trend <- arrangeGrob(p_acc, p_auc, nrow = 1)
ggsave(file.path(PLOT_DIR, "02_metrics_trend_across_sets.png"),
       combined_trend, width = 14, height = 5, dpi = 300)
cat("  Saved: 02_metrics_trend_across_sets.png\n")

# ── Plot C: Per-class AUC heatmap (Test Set) ──
per_cls_test <- per_class_metrics %>%
  filter(Set == "Test") %>%
  select(Model, Class, AUC)

p_heatmap <- ggplot(per_cls_test, aes(x = Class, y = Model, fill = AUC)) +
  geom_tile(colour = "white", linewidth = 0.8) +
  geom_text(aes(label = sprintf("%.4f", AUC)), size = 4, fontface = "bold") +
  scale_fill_gradient(low = "#FEF9C3", high = "#1E40AF",
                      na.value = "grey80", limits = c(0, 1),
                      name = "AUC") +
  labs(title    = "Per-Class AUC Heatmap — Test Set",
       subtitle = "One-vs-Rest (OvR) AUC per tumor class",
       x = "Tumor Class", y = "Model") +
  theme_minimal(base_family = "serif", base_size = 12) +
  theme(plot.title     = element_text(face = "bold"),
        axis.text.x    = element_text(angle = 30, hjust = 1),
        panel.grid     = element_blank(),
        panel.border   = element_rect(colour = "black", fill = NA, linewidth = 0.8))

ggsave(file.path(PLOT_DIR, "03_per_class_auc_heatmap.png"),
       p_heatmap, width = max(8, N_CLASSES * 2 + 3), height = 5, dpi = 300)
cat("  Saved: 03_per_class_auc_heatmap.png\n")

# ── Plot D: Per-class F1 heatmap (Test Set) ──
per_cls_f1 <- per_class_metrics %>%
  filter(Set == "Test") %>%
  select(Model, Class, F1)

p_f1heatmap <- ggplot(per_cls_f1, aes(x = Class, y = Model, fill = F1)) +
  geom_tile(colour = "white", linewidth = 0.8) +
  geom_text(aes(label = sprintf("%.4f", F1)), size = 4, fontface = "bold") +
  scale_fill_gradient(low = "#FEE2E2", high = "#166534",
                      na.value = "grey80", limits = c(0, 1),
                      name = "F1") +
  labs(title    = "Per-Class F1 Score Heatmap — Test Set",
       x = "Tumor Class", y = "Model") +
  theme_minimal(base_family = "serif", base_size = 12) +
  theme(plot.title  = element_text(face = "bold"),
        axis.text.x = element_text(angle = 30, hjust = 1),
        panel.grid  = element_blank(),
        panel.border = element_rect(colour = "black", fill = NA, linewidth = 0.8))

ggsave(file.path(PLOT_DIR, "04_per_class_f1_heatmap.png"),
       p_f1heatmap, width = max(8, N_CLASSES * 2 + 3), height = 5, dpi = 300)
cat("  Saved: 04_per_class_f1_heatmap.png\n")

# ── Plot E: Confusion matrices (Test Set, per model) ──
for (nm in names(all_results)) {
  cm_tbl <- as.data.frame(all_results[[nm]][["Test"]]$cm$table)
  p_cm <- ggplot(cm_tbl, aes(x = Reference, y = Prediction, fill = Freq)) +
    geom_tile(colour = "white") +
    geom_text(aes(label = Freq), size = 5, fontface = "bold") +
    scale_fill_gradient(low = "#EFF6FF", high = "#1D4ED8") +
    labs(title    = paste0(nm, " — Confusion Matrix (Test Set)"),
         subtitle = "Multi-Class") +
    theme_minimal(base_family = "serif", base_size = 11) +
    theme(axis.text.x  = element_text(angle = 30, hjust = 1),
          plot.title   = element_text(face = "bold"),
          panel.border = element_rect(colour = "black", fill = NA, linewidth = 0.8))
  ggsave(file.path(PLOT_DIR, sprintf("05_cm_%s_test.png", nm)),
         p_cm, width = max(6, N_CLASSES * 1.5), height = max(5, N_CLASSES * 1.3), dpi = 300)
}
cat("  Saved: 05_cm_{model}_test.png\n")

# ── Plot F: Ranking by Macro-AUC (Test Set) ──
test_rank <- overall_metrics %>%
  filter(Set == "Test") %>%
  arrange(desc(Macro_AUC)) %>%
  mutate(Rank = row_number(),
         Label = sprintf("#%d %s\n(AUC=%.4f)", Rank, Model, Macro_AUC))

p_rank <- ggplot(test_rank, aes(x = reorder(Model, Macro_AUC), y = Macro_AUC, fill = Model)) +
  geom_col(width = 0.6) +
  geom_text(aes(label = sprintf("%.4f\n(#%d)", Macro_AUC, Rank)),
            hjust = -0.15, size = 3.5, fontface = "bold") +
  scale_fill_brewer(palette = "Set2") +
  coord_flip() +
  ylim(0, 1.12) +
  labs(title    = "Model Ranking by Macro-AUC (Test Set)",
       subtitle = "Candidates for Top-3 Ensemble Selection",
       x = NULL, y = "Macro AUC (OvR)") +
  theme_bw(base_family = "serif", base_size =12) +
  theme(plot.title      = element_text(face = "bold"),
        legend.position = "none")

ggsave(file.path(PLOT_DIR, "06_model_ranking_macro_auc.png"),
       p_rank, width = 9, height = 5, dpi = 300)
cat("  Saved: 06_model_ranking_macro_auc.png\n")

# ── Plot G: Per-class metrics bar (Sensitivity + Specificity + Precision) ──
per_cls_detail <- per_class_metrics %>%
  filter(Set == "Test") %>%
  pivot_longer(cols = c(Sensitivity, Specificity, Precision, F1),
               names_to = "Metric", values_to = "Value")

p_cls_detail <- ggplot(per_cls_detail,
                       aes(x = Class, y = Value, fill = Metric)) +
  geom_col(position = "dodge", width = 0.7) +
  geom_text(aes(label = sprintf("%.3f", Value)),
            position = position_dodge(0.7), vjust = -0.3, size = 2.5) +
  facet_wrap(~ Model, ncol = 2) +
  scale_fill_brewer(palette = "Paired") +
  ylim(0, 1.15) +
  labs(title = "Per-Class Metrics — Test Set",
       x = "Tumor Class", y = "Value") +
  theme_bw(base_family = "serif", base_size =10) +
  theme(axis.text.x = element_text(angle = 30, hjust = 1),
        plot.title  = element_text(face = "bold"))

ggsave(file.path(PLOT_DIR, "07_per_class_metrics_bar.png"),
       p_cls_detail, width = 14, height = 10, dpi = 300)
cat("  Saved: 07_per_class_metrics_bar.png\n")

# ── Plot H: Agreement visualisation (if available) ──
if (!is.null(comparison_all) && nrow(comparison_all) > 0) {
  agree_long <- agreement_df %>%
    select(Model, Our_Accuracy, Friend_Accuracy, Agreement_Rate) %>%
    pivot_longer(-Model, names_to = "Metric", values_to = "Value")

  p_agree <- ggplot(agree_long, aes(x = Model, y = Value, fill = Metric)) +
    geom_col(position = "dodge", width = 0.65) +
    geom_text(aes(label = sprintf("%.4f", Value)),
              position = position_dodge(0.65), vjust = -0.3, size = 3) +
    scale_fill_manual(values = c("Our_Accuracy" = "#3B82F6",
                                  "Friend_Accuracy" = "#F97316",
                                  "Agreement_Rate" = "#10B981")) +
    ylim(0, 1.12) +
    labs(title    = "Our Predictions vs Friend's — Test Set Comparison",
         subtitle = "Agreement = % rows where Our_Predicted == Friend_Predicted",
         x = NULL, y = "Rate", fill = NULL) +
    theme_bw(base_family = "serif", base_size =11) +
    theme(plot.title = element_text(face = "bold"),
          legend.position = "bottom")

  ggsave(file.path(PLOT_DIR, "08_agreement_vs_friend.png"),
         p_agree, width = 10, height = 5, dpi = 300)
  cat("  Saved: 08_agreement_vs_friend.png\n")
}

# ── 11. Save Results to xlsx ──────────────────────────────────
cat("\n=== Saving to xlsx ===\n")

header_style <- createStyle(fontColour = "#FFFFFF", fgFill = "#1E40AF",
                             halign = "CENTER", textDecoration = "bold",
                             border = "Bottom", borderStyle = "medium")

wb <- createWorkbook()

# ── Sheet: README ──
addWorksheet(wb, "README")
readme_text <- data.frame(
  Section = c("Script",    "Created",  "Purpose",
              "Sheet: Overall_Metrics",
              "Sheet: Per_Class_Metrics",
              "Sheet: Metrics_{Model}",
              "Sheet: PerClass_{Model}",
              "Sheet: Pred_{Model}_{Set}",
              "Sheet: All_Predictions",
              "Sheet: CM_Test",
              "Sheet: Comparison_vs_Friend",
              "Sheet: Agreement_Summary",
              "Notes"),
  Description = c(
    "01_single_model_analysis.R",
    as.character(Sys.time()),
    "Verify 4 pre-trained single models; compare with friend xlsx row-by-row",
    "Overall metrics (Accuracy, AUC, F1...) for all models x all sets",
    "Per-class metrics (Sens, Spec, Prec, F1, AUC) for all models x all sets",
    "Metrics filtered to one model across all sets",
    "Per-class metrics filtered to one model",
    "Row-level predictions for one model on one set (with probabilities)",
    "All predictions combined (all models, all sets)",
    "Confusion matrix tables — Test set only",
    "Row-by-row comparison: Our predictions vs Friend's xlsx predictions",
    "Summary statistics of agreement per model",
    paste0("Classes: ", paste(CLASS_LEVELS, collapse=", "),
           " | Train:", nrow(train_set), " Val:", nrow(val_set), " Test:", nrow(test_set))
  ), stringsAsFactors = FALSE
)
writeData(wb, "README", readme_text)
setColWidths(wb, "README", cols = 1:2, widths = c(30, 70))

# ── Sheet: Overall_Metrics ──
addWorksheet(wb, "Overall_Metrics")
writeData(wb, "Overall_Metrics", overall_metrics, headerStyle = header_style)
setColWidths(wb, "Overall_Metrics", cols = 1:ncol(overall_metrics), widths = "auto")
conditionalFormatting(wb, "Overall_Metrics", cols = 3, rows = 2:(nrow(overall_metrics)+1),
                       type = "databar", style = c("#BDD7EE", "#2E75B6"))

# ── Sheet: Per_Class_Metrics ──
addWorksheet(wb, "Per_Class_Metrics")
writeData(wb, "Per_Class_Metrics", per_class_metrics, headerStyle = header_style)
setColWidths(wb, "Per_Class_Metrics", cols = 1:ncol(per_class_metrics), widths = "auto")

# ── Per-model sheets ──
for (nm in names(models)) {
  s1 <- paste0("Metrics_", nm)
  addWorksheet(wb, s1)
  writeData(wb, s1, overall_metrics %>% filter(Model == nm), headerStyle = header_style)
  setColWidths(wb, s1, cols = 1:ncol(overall_metrics), widths = "auto")

  s2 <- paste0("PerClass_", nm)
  addWorksheet(wb, s2)
  writeData(wb, s2, per_class_metrics %>% filter(Model == nm), headerStyle = header_style)
  setColWidths(wb, s2, cols = 1:ncol(per_class_metrics), widths = "auto")
}

# ── Per-model per-set prediction sheets ──
for (nm in names(models)) {
  for (sn in names(sets_list)) {
    sn_abbr <- substr(sn, 1, 4)  # Train/Vali/Test
    sh_name <- paste0("Pred_", nm, "_", sn_abbr)
    if (nchar(sh_name) > 31) sh_name <- substr(sh_name, 1, 31)
    addWorksheet(wb, sh_name)
    pred_data <- all_results[[nm]][[sn]]$pred_rows
    writeData(wb, sh_name, pred_data, headerStyle = header_style)
    setColWidths(wb, sh_name, cols = 1:ncol(pred_data), widths = "auto")
  }
}

# ── Sheet: All_Predictions ──
addWorksheet(wb, "All_Predictions")
writeData(wb, "All_Predictions", all_predictions, headerStyle = header_style)
setColWidths(wb, "All_Predictions", cols = 1:ncol(all_predictions), widths = "auto")

# ── Sheet: CM_Test ──
addWorksheet(wb, "CM_Test")
writeData(wb, "CM_Test", cm_test_tables, headerStyle = header_style)
setColWidths(wb, "CM_Test", cols = 1:ncol(cm_test_tables), widths = "auto")

# ── Sheets: Comparison and Agreement ──
if (nrow(comparison_all) > 0) {
  addWorksheet(wb, "Comparison_vs_Friend")
  writeData(wb, "Comparison_vs_Friend", comparison_all, headerStyle = header_style)
  setColWidths(wb, "Comparison_vs_Friend", cols = 1:ncol(comparison_all), widths = "auto")
}

if (nrow(agreement_df) > 0) {
  addWorksheet(wb, "Agreement_Summary")
  writeData(wb, "Agreement_Summary", agreement_df, headerStyle = header_style)
  setColWidths(wb, "Agreement_Summary", cols = 1:ncol(agreement_df), widths = "auto")
}

# Save workbook
xlsx_path <- file.path(OUT_DIR, "single_model_analysis.xlsx")
saveWorkbook(wb, xlsx_path, overwrite = TRUE)
cat(sprintf("  Saved: %s\n", xlsx_path))

# ── 12. Save RDS for Step 2 ───────────────────────────────────
step1_rds <- file.path(OUT_DIR, "step1_results.rds")
saveRDS(list(
  all_results       = all_results,
  overall_metrics   = overall_metrics,
  per_class_metrics = per_class_metrics,
  all_predictions   = all_predictions,
  comparison_all    = comparison_all,
  agreement_df      = if (exists("agreement_df")) agreement_df else data.frame(),
  friend_preds_all  = if (!is.null(friend_preds_all)) friend_preds_all else data.frame(),
  CLASS_LEVELS      = CLASS_LEVELS,
  N_CLASSES         = N_CLASSES,
  train_set         = train_set,
  val_set           = val_set,
  test_set          = test_set
), step1_rds)
cat(sprintf("  Saved: %s\n", step1_rds))

cat("\n╔══════════════════════════════════════════════════════╗\n")
cat("║  STEP 1 COMPLETE                                      ║\n")
cat(sprintf("║  Output: %-43s║\n", OUT_DIR))
cat("╚══════════════════════════════════════════════════════╝\n")
