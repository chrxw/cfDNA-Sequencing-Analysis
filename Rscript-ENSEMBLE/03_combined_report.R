# ============================================================
#  MULTI-CLASS ENSEMBLE — STEP 3: COMBINED REPORT
#
#  วัตถุประสงค์:
#    สร้างไฟล์ Excel รวมทุกอย่างในไฟล์เดียว สำหรับเปิดดูหรือแชร์ต่อ
#    ประกอบด้วย:
#      • ผลของ single model (ของเพื่อน — official)
#      • ผลของ single model (ที่เราเอามา retest)
#      • ผลของ ensemble (Hard Vote + Soft Vote)
#      • เปรียบเทียบ row-by-row ทุกโมเดลในตารางเดียว
#
#  Inputs:
#    data/reference/ML_ConfusionMetrics_multi.xlsx (metrics เพื่อน)
#    data/reference/ML_predictions_multi.xlsx (predictions เพื่อน)
#    data/reference/{model}_tuned_metrics_multi_seed.rds
#    results/01_single_model/step1_results.rds
#    results/02_ensemble/ensemble_model.rds
#
#  Output:
#    results/combined_report_multi.xlsx
# ============================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(openxlsx)
})

cat("╔══════════════════════════════════════════════════════╗\n")
cat("║  STEP 3: COMBINED REPORT — MULTI-CLASS               ║\n")
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

OUT_FILE <- file.path(RESULT_DIR, "combined_report_multi.xlsx")

# ── 2. Load Step 1 & Step 2 Results ──────────────────────────
cat("=== Loading step results ===\n")
s1 <- readRDS(STEP1_RDS)
s2 <- readRDS(STEP2_RDS)

CLASS_LEVELS  <- s1$CLASS_LEVELS
N_CLASSES     <- s1$N_CLASSES
test_set      <- s1$test_set
overall_ours  <- s1$overall_metrics   # all sets
per_cls_ours  <- s1$per_class_metrics
all_preds     <- s1$all_predictions

top3_names      <- s2$top3_names
best_model_name <- s2$best_model_name
hv_metrics      <- s2$hv_metrics
sv_metrics      <- s2$sv_metrics
hv_per_class    <- s2$hv_per_class
sv_per_class    <- s2$sv_per_class
full_comparison <- s2$full_comparison
full_per_class  <- s2$full_per_class
pred_wide       <- s2$pred_wide
all_6_preds     <- s2$all_6_preds

cat(sprintf("  Classes: %s\n", paste(CLASS_LEVELS, collapse=", ")))
cat(sprintf("  Test rows: %d\n", nrow(test_set)))

# ── 3. Load Friend's Official Metrics ────────────────────────
cat("\n=== Loading friend's official results ===\n")

MODEL_NAMES    <- c("KNN", "SVM", "XGB", "RF")
MODEL_RDS_MAP  <- c(
  KNN = "knn_tuned_metrics_multi_seed.rds",
  SVM = "svm_tuned_metrics_multi_seed.rds",
  XGB = "xgb_tuned_metrics_multi_seed.rds",
  RF  = "rf_tuned_metrics_multi_seed.rds"
)
MODEL_FULL_RESULTS_MAP <- c(
  KNN = "knn_results_multi_seed.rds",
  SVM = "svm_results_multi_seed.rds",
  XGB = "xgb_results_multi_seed.rds",
  RF  = "rf_results_multi_seed.rds"
)

# ── 3a. Friend metrics from ConfusionMetrics xlsx ──
friend_cm_sheets <- list()
if (file.exists(FRIEND_METRICS_XLSX)) {
  sheet_nms <- tryCatch(getSheetNames(FRIEND_METRICS_XLSX), error = function(e) character(0))
  for (sh in sheet_nms) {
    df <- tryCatch(read.xlsx(FRIEND_METRICS_XLSX, sheet = sh), error = function(e) NULL)
    if (!is.null(df)) {
      df$Model_Sheet <- sh
      friend_cm_sheets[[sh]] <- df
    }
  }
  cat(sprintf("  ML_ConfusionMetrics_multi.xlsx — sheets: %s\n",
              paste(sheet_nms, collapse=", ")))
} else {
  cat("  WARNING: ML_ConfusionMetrics_multi.xlsx not found\n")
}

# ── 3b. Friend metrics from tuned_metrics rds ──
friend_rds_metrics <- list()
for (nm in names(MODEL_RDS_MAP)) {
  rds_path <- file.path(FRIEND_RESULT_DIR, MODEL_RDS_MAP[[nm]])
  if (file.exists(rds_path)) {
    df <- tryCatch(readRDS(rds_path), error = function(e) NULL)
    if (!is.null(df) && is.data.frame(df)) {
      df$Model <- nm
      friend_rds_metrics[[nm]] <- df
      cat(sprintf("  Loaded %s metrics rds: %d rows x %d cols\n", nm, nrow(df), ncol(df)))
    }
  }
}
friend_metrics_df <- bind_rows(friend_rds_metrics)

# ── 3c. Friend predictions from ML_predictions_multi.xlsx ──
friend_pred_sheets <- list()
if (file.exists(FRIEND_PRED_XLSX)) {
  sheet_nms <- tryCatch(getSheetNames(FRIEND_PRED_XLSX), error = function(e) character(0))
  for (sh in sheet_nms) {
    df <- tryCatch(read.xlsx(FRIEND_PRED_XLSX, sheet = sh), error = function(e) NULL)
    if (!is.null(df)) {
      df$Sheet_Name <- sh
      friend_pred_sheets[[sh]] <- df
    }
  }
  cat(sprintf("  ML_predictions_multi.xlsx — sheets: %s\n",
              paste(sheet_nms, collapse=", ")))
} else {
  cat("  WARNING: ML_predictions_multi.xlsx not found\n")
}

# ── 4. Build the Unified Metrics Comparison Table ─────────────
cat("\n=== Building unified metrics comparison ===\n")

# ── 4a. Friend's metrics (from rds or xlsx) ──

# Try to build a clean table from friend rds metrics
# Expected format: Metric col (Accuracy/AUC/Precision/Recall/F1), Train/Validation/Test cols, Model col
build_friend_metrics_table <- function(friend_metrics_df) {
  if (nrow(friend_metrics_df) == 0) return(data.frame())

  # Try to detect if format is: Metric | Train | Validation | Test | Model
  if (all(c("Metric", "Model") %in% names(friend_metrics_df))) {
    set_cols <- intersect(c("Train", "Validation", "Test"), names(friend_metrics_df))
    if (length(set_cols) > 0) {
      long_df <- friend_metrics_df %>%
        pivot_longer(cols = all_of(set_cols), names_to = "Set", values_to = "Value") %>%
        mutate(Source = "Friend_Official",
               Value  = round(as.numeric(Value), 4))
      return(long_df)
    }
  }
  # Fallback: return as-is with Source label
  friend_metrics_df$Source <- "Friend_Official"
  friend_metrics_df
}

friend_metrics_long <- build_friend_metrics_table(friend_metrics_df)

# ── 4b. Our retested metrics ──
our_test_metrics <- overall_ours %>%
  filter(Set == "Test") %>%
  mutate(Source = "Our_Retest") %>%
  select(Source, Model, Set, Accuracy, Kappa,
         Macro_AUC, Macro_F1, Macro_Sensitivity, Macro_Specificity, Macro_Precision)

our_all_metrics <- overall_ours %>%
  mutate(Source = "Our_Retest") %>%
  select(Source, Model, Set, Accuracy, Kappa,
         Macro_AUC, Macro_F1, Macro_Sensitivity, Macro_Specificity, Macro_Precision)

# ── 4c. Ensemble metrics ──
ens_metrics_table <- bind_rows(
  hv_metrics %>%
    mutate(Source = "Our_Ensemble", Set = "Test") %>%
    select(Source, Model, Set, Accuracy, Kappa,
           Macro_AUC, Macro_F1, Macro_Sensitivity, Macro_Specificity, Macro_Precision),
  sv_metrics %>%
    mutate(Source = "Our_Ensemble", Set = "Test") %>%
    select(Source, Model, Set, Accuracy, Kappa,
           Macro_AUC, Macro_F1, Macro_Sensitivity, Macro_Specificity, Macro_Precision)
)

# ── 4d. Pivot friend metrics into same shape if possible ──
friend_pivoted <- data.frame()
if (nrow(friend_metrics_long) > 0 && "Metric" %in% names(friend_metrics_long)) {
  # Convert long → wide
  key_metrics <- c("Accuracy", "AUC", "Precision", "Recall", "F1 Score", "F1")
  friend_wide_list <- list()
  for (nm in unique(friend_metrics_long$Model)) {
    for (sn in unique(friend_metrics_long$Set)) {
      sub <- friend_metrics_long %>%
        filter(Model == nm, Set == sn)
      if (nrow(sub) == 0) next
      row <- data.frame(Source = "Friend_Official", Model = nm, Set = sn,
                        stringsAsFactors = FALSE)
      for (met in sub$Metric) {
        col_name <- gsub(" ", "_", met)
        row[[col_name]] <- sub$Value[sub$Metric == met]
      }
      friend_wide_list[[paste(nm, sn)]] <- row
    }
  }
  if (length(friend_wide_list) > 0) {
    friend_pivoted <- bind_rows(friend_wide_list)
    # Rename to match our naming
    if ("AUC" %in% names(friend_pivoted)) friend_pivoted$Macro_AUC <- friend_pivoted$AUC
    if ("F1_Score" %in% names(friend_pivoted)) friend_pivoted$Macro_F1 <- friend_pivoted$F1_Score
    if ("F1" %in% names(friend_pivoted)) {
      if (!"Macro_F1" %in% names(friend_pivoted)) friend_pivoted$Macro_F1 <- friend_pivoted$F1
    }
    if ("Precision" %in% names(friend_pivoted)) friend_pivoted$Macro_Precision <- friend_pivoted$Precision
    if ("Recall" %in% names(friend_pivoted)) friend_pivoted$Macro_Sensitivity <- friend_pivoted$Recall
  }
}

# ── 4e. Build master comparison table ──
safe_select <- function(df, cols) {
  present <- intersect(cols, names(df))
  missing_cols <- setdiff(cols, names(df))
  df_sub <- df[, present, drop = FALSE]
  for (mc in missing_cols) df_sub[[mc]] <- NA_real_
  df_sub[, cols]
}

std_cols <- c("Source", "Model", "Set",
              "Accuracy", "Kappa", "Macro_AUC", "Macro_F1",
              "Macro_Sensitivity", "Macro_Specificity", "Macro_Precision")

master_comparison <- bind_rows(
  if (nrow(friend_pivoted) > 0) safe_select(friend_pivoted, std_cols) else NULL,
  safe_select(our_all_metrics,   std_cols),
  safe_select(ens_metrics_table, std_cols)
) %>%
  mutate(
    Source_Order = case_when(
      Source == "Friend_Official" ~ 1,
      Source == "Our_Retest"      ~ 2,
      Source == "Our_Ensemble"    ~ 3,
      TRUE                        ~ 4
    ),
    Set_Order = case_when(
      Set == "Train"      ~ 1,
      Set == "Validation" ~ 2,
      Set == "Test"       ~ 3,
      TRUE                ~ 4
    )
  ) %>%
  arrange(Source_Order, Model, Set_Order) %>%
  select(-Source_Order, -Set_Order)

cat(sprintf("  Master comparison: %d rows\n", nrow(master_comparison)))

# ── 5. Build Prediction Tables ────────────────────────────────
cat("\n=== Building prediction tables ===\n")

# ── 5a. Friend's predictions (Test set, per model) ──
friend_preds_test <- list()
detect_col <- function(df, patterns) {
  hits <- names(df)[grepl(paste(patterns, collapse="|"), names(df), ignore.case=TRUE)]
  if (length(hits) > 0) hits[1] else NA_character_
}

for (sh in names(friend_pred_sheets)) {
  df <- friend_pred_sheets[[sh]]
  set_col <- detect_col(df, c("^set$","dataset","split"))
  if (!is.na(set_col)) {
    test_rows <- df %>% filter(grepl("test", .[[set_col]], ignore.case=TRUE))
    if (nrow(test_rows) > 0) {
      friend_preds_test[[sh]] <- test_rows %>% mutate(Source = "Friend_Official")
    } else {
      friend_preds_test[[sh]] <- df %>% mutate(Source = "Friend_Official")
    }
  } else {
    friend_preds_test[[sh]] <- df %>% mutate(Source = "Friend_Official")
  }
}

# ── 5b. Our predictions (Test set, per model) ──
our_preds_test <- list()
for (nm in unique(all_preds$Model)) {
  our_preds_test[[nm]] <- all_preds %>%
    filter(Model == nm, Set == "Test") %>%
    mutate(Source = "Our_Retest")
}

# ── 5c. Ensemble predictions ──
hv_preds <- all_6_preds %>%
  filter(Model == "Ensemble_HardVote") %>%
  mutate(Source = "Our_Ensemble")

sv_preds <- all_6_preds %>%
  filter(Model == "Ensemble_SoftVote") %>%
  mutate(Source = "Our_Ensemble")

# ── 6. Build Wide Row-by-Row Table (All Sources) ──────────────
cat("  Building wide comparison table (all models per row)...\n")

# pred_wide already has all single models + HV + SV predictions
# Add Source labels and friend predictions for test set
wide_table <- pred_wide

# Append friend predictions per model if available
for (sh in names(friend_preds_test)) {
  fp <- friend_preds_test[[sh]]
  ri_col  <- detect_col(fp, c("row_id","rowid","row.id"))
  pr_col  <- detect_col(fp, c("predicted","prediction","pred_class"))

  # Try to map sheet name to a model name
  nm_match <- names(MODEL_RDS_MAP)[sapply(names(MODEL_RDS_MAP), function(x)
    grepl(x, sh, ignore.case=TRUE))]
  if (length(nm_match) == 0) nm_match <- sh

  if (!is.na(ri_col) && !is.na(pr_col)) {
    fp_sub <- fp %>%
      select(Row_id = all_of(ri_col),
             !!paste0("Friend_", nm_match[1], "_Pred") := all_of(pr_col)) %>%
      mutate(Row_id = as.integer(Row_id))

    wide_table <- wide_table %>%
      left_join(fp_sub, by = "Row_id")

    # Add Correct column
    pred_col <- paste0("Friend_", nm_match[1], "_Pred")
    if (pred_col %in% names(wide_table)) {
      wide_table[[paste0("Friend_", nm_match[1], "_Correct")]] <-
        wide_table$Actual == wide_table[[pred_col]]
    }
  }
}

# Summary per row: how many models predicted correctly
all_correct_cols <- names(wide_table)[grepl("_Correct$", names(wide_table))]
wide_table$N_Models_Correct <- rowSums(wide_table[, all_correct_cols, drop=FALSE], na.rm=TRUE)
wide_table$Total_Models_With_Data <- rowSums(!is.na(wide_table[, all_correct_cols, drop=FALSE]))

cat(sprintf("  Wide table: %d rows × %d columns\n", nrow(wide_table), ncol(wide_table)))

# ── 7. Per-Class Metrics (all 6 models) ──────────────────────
per_class_all <- full_per_class %>%
  mutate(Model = gsub(" \\(Top3\\)", "", Model)) %>%
  arrange(Class, Model)

# ── 8. Test-Set Accuracy Summary ─────────────────────────────
test_summary <- master_comparison %>%
  filter(Set == "Test" | is.na(Set)) %>%
  arrange(desc(Macro_AUC)) %>%
  mutate(Rank = row_number())

# ── 9. Create Workbook ─────────────────────────────────────────
cat("\n=== Building workbook ===\n")

wb <- createWorkbook()

# ── Styles ──
style_header_blue <- createStyle(
  fontColour = "#FFFFFF", fgFill = "#1E3A8A",
  halign = "CENTER", textDecoration = "bold",
  border = "Bottom", borderStyle = "medium", wrapText = TRUE
)
style_header_green <- createStyle(
  fontColour = "#FFFFFF", fgFill = "#065F46",
  halign = "CENTER", textDecoration = "bold",
  border = "Bottom", borderStyle = "medium", wrapText = TRUE
)
style_header_purple <- createStyle(
  fontColour = "#FFFFFF", fgFill = "#5B21B6",
  halign = "CENTER", textDecoration = "bold",
  border = "Bottom", borderStyle = "medium", wrapText = TRUE
)
style_header_orange <- createStyle(
  fontColour = "#FFFFFF", fgFill = "#92400E",
  halign = "CENTER", textDecoration = "bold",
  border = "Bottom", borderStyle = "medium", wrapText = TRUE
)
style_section_friend   <- createStyle(fgFill = "#DBEAFE", halign = "CENTER")
style_section_ours     <- createStyle(fgFill = "#D1FAE5", halign = "CENTER")
style_section_ensemble <- createStyle(fgFill = "#EDE9FE", halign = "CENTER")
style_correct          <- createStyle(fgFill = "#DCFCE7")
style_wrong            <- createStyle(fgFill = "#FEE2E2")
style_bold             <- createStyle(textDecoration = "bold")

# ── Helper: write sheet with auto-width ──
add_sheet <- function(wb, name, data, header_style = style_header_blue,
                       freeze = TRUE, auto_filter = TRUE) {
  addWorksheet(wb, name)
  if (nrow(data) == 0) {
    writeData(wb, name, data.frame(Note = "(No data available)"))
    return(invisible(NULL))
  }
  writeData(wb, name, data, headerStyle = header_style,
             withFilter = auto_filter)
  setColWidths(wb, name, cols = seq_along(data), widths = "auto")
  if (freeze) freezePane(wb, name, firstRow = TRUE)
  invisible(NULL)
}

# ══════════════════════════════════════════════════════════
# SHEET 1: README
# ══════════════════════════════════════════════════════════
addWorksheet(wb, "README2")
readme_df <- data.frame(
  "#"  = seq(1, 17),
  Sheet = c(
    "README",
    "── SUMMARY ──",
    "Metrics_Comparison_All",
    "Test_Set_Ranking",
    "── FRIEND'S RESULTS (Official) ──",
    "Friend_Metrics_Official",
    "Friend_Predictions",
    paste0("Friend_Pred_", names(friend_pred_sheets)[seq_len(min(4, length(friend_pred_sheets)))]),
    "── OUR RESULTS ──",
    "Our_Metrics_All_Sets",
    "Our_Metrics_Test",
    "Our_PerClass_Test",
    "Our_Predictions_Test",
    "── ENSEMBLE RESULTS ──",
    "Ensemble_Config",
    "Ensemble_Metrics",
    "Ensemble_PerClass",
    "Ensemble_Predictions",
    "── COMPARISON ──",
    "RowByRow_AllModels",
    "PerClass_All6Models"
  )[1:17],
  Description = c(
    "This file — overview of all sheets",
    "",
    "Master metrics table: Friend + Our Retest + Ensemble | Color: Blue=Friend, Green=Ours, Purple=Ensemble",
    "Test-set only, ranked by Macro-AUC — Quick overview of best model",
    "",
    "Friend's official metrics from ConfusionMetrics xlsx + rds (Accuracy/AUC/F1 per Train/Val/Test)",
    paste0("Friend's predictions combined — all models, all sets (from ML_predictions_multi.xlsx)"),
    paste0("Friend's predictions — sheet '", names(friend_pred_sheets)[seq_len(min(4, length(friend_pred_sheets)))],
           "' separately")[1:min(4, length(friend_pred_sheets))],
    "",
    "Our retested single models — Train + Validation + Test metrics",
    "Our retested single models — Test only",
    "Per-class metrics: Sensitivity, Specificity, Precision, F1, AUC — Test set",
    "Row-level predictions for all 4 single models on Test set (with class probabilities)",
    "",
    paste0("Top-3 selection: ", paste(top3_names, collapse=" > "), " | Strategy: Hard Vote + Soft Vote"),
    "Ensemble metrics: Hard Vote vs Soft Vote (Accuracy / AUC / F1 / Sensitivity / Specificity)",
    "Ensemble per-class metrics: Sensitivity, Specificity, Precision, F1, AUC per tumor class",
    "Ensemble row-level predictions (both Hard Vote and Soft Vote) with probabilities",
    "",
    "MAIN COMPARISON — Every test row: predictions from Friend's + Ours + Ensemble side-by-side",
    "Per-class metrics heatmap data for all 6 models (4 single + 2 ensemble)"
  )[1:17],
  "Color Code" = c(
    "", "", "Blue=Friend | Green=Our Retest | Purple=Ensemble", "",
    "", "Blue header", "Blue header",
    rep("Blue header", min(4, length(friend_pred_sheets))),
    "", "Green header", "Green header", "Green header", "Green header",
    "", "Purple header", "Purple header", "Purple header", "Purple header",
    "", "Blue header", "Blue header"
  )[1:17],
  check.names = FALSE, stringsAsFactors = FALSE
)
addWorksheet(wb, "README")
writeData(wb, "README", readme_df, headerStyle = style_header_blue)
setColWidths(wb, "README", cols = 1:4, widths = c(5, 30, 70, 25))
# Re-add README since first addWorksheet was before the data setup
# (already done via add_sheet logic below - note we wrote directly)
cat("  Sheet: README\n")

# ══════════════════════════════════════════════════════════
# SHEET 2: Master Metrics Comparison (all sources)
# ══════════════════════════════════════════════════════════
addWorksheet(wb, "Metrics_Comparison_All")
if (nrow(master_comparison) > 0) {
  writeData(wb, "Metrics_Comparison_All", master_comparison,
            headerStyle = style_header_blue, withFilter = TRUE)
  setColWidths(wb, "Metrics_Comparison_All", cols = seq_along(master_comparison), widths = "auto")
  freezePane(wb, "Metrics_Comparison_All", firstRow = TRUE)

  # Color rows by source
  n_rows <- nrow(master_comparison)
  for (i in seq_len(n_rows)) {
    src <- master_comparison$Source[i]
    sty <- switch(src,
                   "Friend_Official" = style_section_friend,
                   "Our_Retest"      = style_section_ours,
                   "Our_Ensemble"    = style_section_ensemble,
                   NULL)
    if (!is.null(sty)) {
      addStyle(wb, "Metrics_Comparison_All", style = sty,
               rows = i + 1, cols = 1:ncol(master_comparison), stack = TRUE)
    }
  }
  # Data bar on Macro_AUC column
  auc_col_idx <- which(names(master_comparison) == "Macro_AUC")
  if (length(auc_col_idx) > 0) {
    conditionalFormatting(wb, "Metrics_Comparison_All",
                           cols = auc_col_idx, rows = 2:(n_rows+1),
                           type = "databar", style = c("#A7F3D0", "#065F46"))
  }
}
cat("  Sheet: Metrics_Comparison_All\n")

# ══════════════════════════════════════════════════════════
# SHEET 3: Test Set Ranking
# ══════════════════════════════════════════════════════════
add_sheet(wb, "Test_Set_Ranking", test_summary, style_header_blue)
# Highlight ensemble rows
for (i in seq_len(nrow(test_summary))) {
  if (grepl("Ensemble", test_summary$Model[i])) {
    addStyle(wb, "Test_Set_Ranking", style_section_ensemble,
             rows = i+1, cols = 1:ncol(test_summary), stack = TRUE)
  }
}
cat("  Sheet: Test_Set_Ranking\n")

# ══════════════════════════════════════════════════════════
# SHEET 4: Friend's Official Metrics (from xlsx)
# ══════════════════════════════════════════════════════════
if (length(friend_cm_sheets) > 0) {
  friend_cm_all <- bind_rows(lapply(names(friend_cm_sheets), function(sh) {
    df <- friend_cm_sheets[[sh]]
    if (!"Model" %in% names(df)) df$Model <- sh
    df
  }))
  add_sheet(wb, "Friend_Metrics_Official", friend_cm_all, style_header_blue)
} else if (nrow(friend_metrics_df) > 0) {
  add_sheet(wb, "Friend_Metrics_Official", friend_metrics_df, style_header_blue)
} else {
  addWorksheet(wb, "Friend_Metrics_Official")
  writeData(wb, "Friend_Metrics_Official", data.frame(Note="Friend metrics xlsx not found"))
}
cat("  Sheet: Friend_Metrics_Official\n")

# ══════════════════════════════════════════════════════════
# SHEET 5: Friend's Predictions Combined
# ══════════════════════════════════════════════════════════
if (length(friend_pred_sheets) > 0) {
  friend_preds_combined <- bind_rows(lapply(names(friend_pred_sheets), function(sh) {
    df <- friend_pred_sheets[[sh]]
    # Add model name from sheet if no model col
    if (!"Model" %in% names(df)) df$Model <- sh
    df
  }))
  add_sheet(wb, "Friend_Predictions", friend_preds_combined, style_header_blue)
  cat("  Sheet: Friend_Predictions\n")

  # Individual sheets per model
  for (sh in names(friend_pred_sheets)) {
    sh_safe <- paste0("Friend_", substr(sh, 1, 26))
    add_sheet(wb, sh_safe, friend_pred_sheets[[sh]], style_header_blue)
    cat(sprintf("  Sheet: %s\n", sh_safe))
  }
} else {
  addWorksheet(wb, "Friend_Predictions")
  writeData(wb, "Friend_Predictions", data.frame(Note="Friend predictions xlsx not found"))
  cat("  Sheet: Friend_Predictions (empty — file not found)\n")
}

# ══════════════════════════════════════════════════════════
# SHEET 6: Our Retested Metrics — All Sets
# ══════════════════════════════════════════════════════════
our_all_for_sheet <- overall_ours %>%
  mutate(Source = "Our_Retest") %>%
  select(Source, everything()) %>%
  mutate(Set = factor(Set, levels = c("Train","Validation","Test"))) %>%
  arrange(Model, Set)

add_sheet(wb, "Our_Metrics_All_Sets", our_all_for_sheet, style_header_green)
# Color by Set
for (i in seq_len(nrow(our_all_for_sheet))) {
  sty <- switch(as.character(our_all_for_sheet$Set[i]),
                "Train"      = createStyle(fgFill="#F0FDF4"),
                "Validation" = createStyle(fgFill="#DCFCE7"),
                "Test"       = createStyle(fgFill="#A7F3D0"),
                NULL)
  if (!is.null(sty))
    addStyle(wb, "Our_Metrics_All_Sets", sty, rows=i+1, cols=1:ncol(our_all_for_sheet), stack=TRUE)
}
cat("  Sheet: Our_Metrics_All_Sets\n")

# ══════════════════════════════════════════════════════════
# SHEET 7: Our Retested Metrics — Test Only
# ══════════════════════════════════════════════════════════
our_test_for_sheet <- overall_ours %>%
  filter(Set == "Test") %>%
  arrange(desc(Macro_AUC)) %>%
  mutate(Rank = row_number())

add_sheet(wb, "Our_Metrics_Test", our_test_for_sheet, style_header_green)
auc_col <- which(names(our_test_for_sheet) == "Macro_AUC")
if (length(auc_col) > 0) {
  conditionalFormatting(wb, "Our_Metrics_Test", cols = auc_col,
                         rows = 2:(nrow(our_test_for_sheet)+1),
                         type = "databar", style = c("#BBF7D0","#14532D"))
}
cat("  Sheet: Our_Metrics_Test\n")

# ══════════════════════════════════════════════════════════
# SHEET 8: Our Per-Class Metrics — Test Only
# ══════════════════════════════════════════════════════════
our_pc_test <- per_cls_ours %>%
  filter(Set == "Test") %>%
  arrange(Model, Class) %>%
  select(-Set)

add_sheet(wb, "Our_PerClass_Test", our_pc_test, style_header_green)
cat("  Sheet: Our_PerClass_Test\n")

# ══════════════════════════════════════════════════════════
# SHEET 9: Our Predictions — Test Set (all 4 models combined)
# ══════════════════════════════════════════════════════════
our_preds_test_df <- all_preds %>%
  filter(Set == "Test") %>%
  select(-Set)

add_sheet(wb, "Our_Predictions_Test", our_preds_test_df, style_header_green)
# Highlight Correct/Wrong
correct_col_idx <- which(names(our_preds_test_df) == "Correct")
if (length(correct_col_idx) > 0) {
  for (i in seq_len(nrow(our_preds_test_df))) {
    sty <- if (isTRUE(our_preds_test_df$Correct[i])) style_correct else style_wrong
    addStyle(wb, "Our_Predictions_Test", sty, rows=i+1,
             cols=correct_col_idx, stack=TRUE)
  }
}
cat("  Sheet: Our_Predictions_Test\n")

# ══════════════════════════════════════════════════════════
# SHEET 10: Ensemble Config
# ══════════════════════════════════════════════════════════
addWorksheet(wb, "Ensemble_Config")
ens_config <- data.frame(
  Parameter = c(
    "Ensemble type",
    "Base model count (top N)",
    "Ranking metric",
    "Rank 1 — Best model",
    "Rank 2",
    "Rank 3",
    "Tie-break model",
    "Hard Vote strategy",
    "Soft Vote strategy",
    "Test set size",
    "Classes"
  ),
  Value = c(
    "Hard Vote + Soft Vote",
    as.character(length(top3_names)),
    "Macro-AUC (OvR, Test Set)",
    paste0(top3_names[1], " (", round(s2$full_comparison$Macro_AUC[s2$full_comparison$Model == top3_names[1]][1], 4), ")"),
    paste0(top3_names[2], " (", round(s2$full_comparison$Macro_AUC[s2$full_comparison$Model == top3_names[2]][1], 4), ")"),
    paste0(top3_names[3], " (", round(s2$full_comparison$Macro_AUC[s2$full_comparison$Model == top3_names[3]][1], 4), ")"),
    best_model_name,
    "Majority vote of 3 models; ties resolved by best model's prediction",
    "Average probability matrix of top-3 models; argmax as final class",
    as.character(nrow(test_set)),
    paste(CLASS_LEVELS, collapse=", ")
  ),
  stringsAsFactors = FALSE
)
writeData(wb, "Ensemble_Config", ens_config, headerStyle = style_header_purple)
setColWidths(wb, "Ensemble_Config", cols = 1:2, widths = c(35, 65))
cat("  Sheet: Ensemble_Config\n")

# ══════════════════════════════════════════════════════════
# SHEET 11: Ensemble Metrics (Hard Vote + Soft Vote side-by-side)
# ══════════════════════════════════════════════════════════
ens_both_metrics <- bind_rows(
  hv_metrics %>% mutate(Strategy = "Hard Vote"),
  sv_metrics %>% mutate(Strategy = "Soft Vote")
) %>% select(Strategy, Model, everything())

add_sheet(wb, "Ensemble_Metrics", ens_both_metrics, style_header_purple)
cat("  Sheet: Ensemble_Metrics\n")

# ══════════════════════════════════════════════════════════
# SHEET 12: Ensemble Per-Class Metrics
# ══════════════════════════════════════════════════════════
ens_pc <- bind_rows(
  hv_per_class %>% mutate(Strategy = "Hard Vote"),
  sv_per_class %>% mutate(Strategy = "Soft Vote")
) %>%
  mutate(Model = gsub(" \\(Top3\\)", "", Model)) %>%
  select(Strategy, Model, Class, everything())

add_sheet(wb, "Ensemble_PerClass", ens_pc, style_header_purple)
cat("  Sheet: Ensemble_PerClass\n")

# ══════════════════════════════════════════════════════════
# SHEET 13: Ensemble Predictions (Hard + Soft combined)
# ══════════════════════════════════════════════════════════
ens_preds_combined <- bind_rows(
  hv_preds %>% mutate(Strategy = "Hard Vote") %>% select(Strategy, everything()),
  sv_preds %>% mutate(Strategy = "Soft Vote") %>% select(Strategy, everything())
) %>% arrange(Strategy, Row_id)

add_sheet(wb, "Ensemble_Predictions", ens_preds_combined, style_header_purple)
cat("  Sheet: Ensemble_Predictions\n")

# ══════════════════════════════════════════════════════════
# SHEET 14: Row-by-Row — ALL MODELS (main comparison sheet)
# ══════════════════════════════════════════════════════════
addWorksheet(wb, "RowByRow_AllModels")
writeData(wb, "RowByRow_AllModels", wide_table,
          headerStyle = style_header_blue, withFilter = TRUE)
setColWidths(wb, "RowByRow_AllModels", cols = seq_along(wide_table), widths = "auto")
freezePane(wb, "RowByRow_AllModels", firstRow = TRUE, firstCol = TRUE)

# Color rows where all models agree (correct vs wrong)
n_all_correct_col <- which(names(wide_table) == "N_Models_Correct")
if (length(n_all_correct_col) > 0 && nrow(wide_table) > 0) {
  max_possible <- wide_table$Total_Models_With_Data
  for (i in seq_len(nrow(wide_table))) {
    n_corr <- wide_table$N_Models_Correct[i]
    total  <- max_possible[i]
    if (!is.na(n_corr) && !is.na(total) && total > 0) {
      if (n_corr == total) {
        addStyle(wb, "RowByRow_AllModels", createStyle(fgFill="#DCFCE7"),
                 rows=i+1, cols=1:ncol(wide_table), stack=TRUE)
      } else if (n_corr == 0) {
        addStyle(wb, "RowByRow_AllModels", createStyle(fgFill="#FEE2E2"),
                 rows=i+1, cols=1:ncol(wide_table), stack=TRUE)
      }
    }
  }
}
cat("  Sheet: RowByRow_AllModels\n")

# ══════════════════════════════════════════════════════════
# SHEET 15: Per-Class Metrics — All 6 Models
# ══════════════════════════════════════════════════════════
per_class_clean <- per_class_all %>%
  mutate(Model = gsub(" \\(Top3\\)", "", Model)) %>%
  arrange(Class, Model)

add_sheet(wb, "PerClass_All6Models", per_class_clean, style_header_blue)
auc_pc_col <- which(names(per_class_clean) == "AUC")
if (length(auc_pc_col) > 0) {
  conditionalFormatting(wb, "PerClass_All6Models", cols = auc_pc_col,
                         rows = 2:(nrow(per_class_clean)+1),
                         type = "colorScale",
                         style = c("#FEF3C7","#FDE68A","#22C55E"))
}
cat("  Sheet: PerClass_All6Models\n")

# ── Reorder sheets for better UX ──────────────────────────────
# (README first, then summary, then detail)
worksheetOrder(wb) <- order(match(names(wb), c(
  "README",
  "Metrics_Comparison_All",
  "Test_Set_Ranking",
  "Ensemble_Config",
  "Ensemble_Metrics",
  "Ensemble_PerClass",
  "Ensemble_Predictions",
  "Our_Metrics_All_Sets",
  "Our_Metrics_Test",
  "Our_PerClass_Test",
  "Our_Predictions_Test",
  "Friend_Metrics_Official",
  "Friend_Predictions",
  names(wb)[grepl("^Friend_Pred_", names(wb))],
  "RowByRow_AllModels",
  "PerClass_All6Models"
)))

# ── Save ──────────────────────────────────────────────────────
saveWorkbook(wb, OUT_FILE, overwrite = TRUE)
cat(sprintf("\n  ✔ Saved: %s\n", OUT_FILE))

# ── Summary ───────────────────────────────────────────────────
cat("\n╔══════════════════════════════════════════════════════╗\n")
cat("║  COMBINED REPORT COMPLETE                             ║\n")
cat("╚══════════════════════════════════════════════════════╝\n")
cat(sprintf("  File : %s\n", OUT_FILE))
cat(sprintf("  Sheets: %d total\n", length(names(wb))))
cat(sprintf("  Test rows covered: %d\n\n", nrow(test_set)))
cat("  Sheet list:\n")
for (sh in names(wb)) cat(sprintf("    • %s\n", sh))
