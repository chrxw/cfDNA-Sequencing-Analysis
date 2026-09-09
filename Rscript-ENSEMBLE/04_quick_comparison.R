# ============================================================
#  MULTI-CLASS ENSEMBLE — STEP 4: QUICK COMPARISON REPORT
#
#  สร้างไฟล์ Excel 5 sheets เพื่อดูผลแบบเจาะจงและชัดเจน:
#
#  Sheet 1  Friend_vs_Actual
#           → ผลของเพื่อน vs actual — เห็นชัดว่าผิดที่ตรงไหนบ้าง
#
#  Sheet 2  Ours_vs_Friend
#           → ผลของเรา vs ผลของเพื่อน — ตรงกันไหม?
#
#  Sheet 3  Ours_vs_Friend_vs_Actual
#           → เรา | เพื่อน | actual ในตารางเดียว
#
#  Sheet 4  SingleModels_vs_Ensemble
#           → 4 single model + ensemble ในแต่ละ row
#
#  Sheet 5  Actual_vs_Ensemble
#           → actual vs ensemble (Hard Vote + Soft Vote)
#
#  Output:  results/quick_comparison_multi.xlsx
# ============================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(openxlsx)
})

cat("╔══════════════════════════════════════════════════════╗\n")
cat("║  STEP 4: QUICK COMPARISON REPORT — MULTI-CLASS       ║\n")
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

OUT_FILE <- file.path(RESULT_DIR, "quick_comparison_multi.xlsx")

# ── Load ──────────────────────────────────────────────────────
cat("=== Loading data ===\n")
s1 <- readRDS(STEP1_RDS)
s2 <- readRDS(STEP2_RDS)

CLASS_LEVELS <- s1$CLASS_LEVELS
our_test     <- s1$all_predictions %>% filter(Set == "Test")   # Model | Row_id | Actual | Predicted | Correct
pred_wide    <- s2$pred_wide        # wide: Row_id | Actual | {model}_Pred | {model}_Correct | ...
all_6_preds  <- s2$all_6_preds
top3_names   <- s2$top3_names

MODEL_NAMES  <- c("KNN", "SVM", "XGB", "RF")
cat(sprintf("  Test rows: %d | Classes: %s\n",
            nrow(s1$test_set), paste(CLASS_LEVELS, collapse=", ")))

# ── Load & normalise friend's predictions ─────────────────────
cat("\n=== Loading friend's xlsx predictions ===\n")

detect_col <- function(df, patterns) {
  hits <- names(df)[grepl(paste(patterns, collapse="|"), names(df), ignore.case=TRUE)]
  if (length(hits)) hits[1] else NA_character_
}

load_friend_test_preds <- function(xlsx_path) {
  if (!file.exists(xlsx_path)) {
    cat("  WARNING: friend xlsx not found.\n")
    return(NULL)
  }
  sheets <- tryCatch(getSheetNames(xlsx_path), error = function(e) character(0))
  out <- list()
  for (sh in sheets) {
    df <- tryCatch(read.xlsx(xlsx_path, sheet = sh), error = function(e) NULL)
    if (is.null(df)) next

    set_col    <- detect_col(df, c("^set$", "dataset", "split"))
    ri_col     <- detect_col(df, c("row_id","rowid","row.id"))
    pred_col   <- detect_col(df, c("^predicted$","^prediction$","pred_class"))
    actual_col <- detect_col(df, c("^actual$","true_label","^true$"))

    if (is.na(ri_col) || is.na(pred_col)) { next }

    # filter to test set
    if (!is.na(set_col)) {
      test_rows <- df %>% filter(grepl("test", .[[set_col]], ignore.case=TRUE))
      if (nrow(test_rows) > 0) df <- test_rows
    }

    df_clean <- data.frame(
      Model            = sh,
      Row_id           = as.integer(df[[ri_col]]),
      Friend_Predicted = as.character(df[[pred_col]]),
      stringsAsFactors = FALSE
    )
    if (!is.na(actual_col))
      df_clean$Actual_in_Friend_xlsx <- as.character(df[[actual_col]])

    out[[sh]] <- df_clean
  }
  if (length(out) == 0) return(NULL)
  bind_rows(out)
}

friend_raw <- load_friend_test_preds(FRIEND_PRED_XLSX)

# Also try from step1 comparison data (already merged)
comparison_step1 <- if (!is.null(s1$comparison_all) && nrow(s1$comparison_all) > 0)
  s1$comparison_all else NULL

# ── Helper: apply row colours ─────────────────────────────────
# colour_map = named list: column_name → list(values_to_colour, style)
# We use a simple loop; typical test sets are small enough
colour_rows <- function(wb, sheet, df, col_name, true_style, false_style) {
  if (!col_name %in% names(df)) return(invisible())
  for (i in seq_len(nrow(df))) {
    val <- df[[col_name]][i]
    sty <- if (isTRUE(val)) true_style else if (identical(val, FALSE)) false_style else NULL
    if (!is.null(sty))
      addStyle(wb, sheet, sty, rows = i + 1, cols = 1:ncol(df), stack = TRUE)
  }
}

colour_rows_by_value <- function(wb, sheet, df, col_name, colour_map) {
  if (!col_name %in% names(df)) return(invisible())
  for (i in seq_len(nrow(df))) {
    v <- as.character(df[[col_name]][i])
    sty <- colour_map[[v]]
    if (!is.null(sty))
      addStyle(wb, sheet, sty, rows = i + 1, cols = 1:ncol(df), stack = TRUE)
  }
}

# ── Styles ─────────────────────────────────────────────────────
h_blue   <- createStyle(fontColour="#FFFFFF", fgFill="#1E3A8A", halign="CENTER",
                         textDecoration="bold", border="Bottom", borderStyle="medium")
h_green  <- createStyle(fontColour="#FFFFFF", fgFill="#14532D", halign="CENTER",
                         textDecoration="bold", border="Bottom", borderStyle="medium")
h_purple <- createStyle(fontColour="#FFFFFF", fgFill="#4C1D95", halign="CENTER",
                         textDecoration="bold", border="Bottom", borderStyle="medium")

s_correct     <- createStyle(fgFill="#DCFCE7")   # light green
s_wrong       <- createStyle(fgFill="#FEE2E2")   # light red
s_agree       <- createStyle(fgFill="#DBEAFE")   # light blue
s_disagree    <- createStyle(fgFill="#FEF3C7")   # light amber
s_both_ok     <- createStyle(fgFill="#DCFCE7")   # green
s_both_bad    <- createStyle(fgFill="#FEE2E2")   # red
s_only_ours   <- createStyle(fgFill="#D1FAE5")   # teal-green
s_only_friend <- createStyle(fgFill="#FEF9C3")   # yellow

write_sheet <- function(wb, name, df, h_style) {
  addWorksheet(wb, name)
  if (nrow(df) == 0) {
    writeData(wb, name, data.frame(Note="(No data — friend xlsx may not be available)"))
    return(invisible())
  }
  writeData(wb, name, df, headerStyle = h_style, withFilter = TRUE)
  setColWidths(wb, name, cols = seq_along(df), widths = "auto")
  freezePane(wb, name, firstRow = TRUE)
}

# ══════════════════════════════════════════════════════════════
# SHEET 1: Friend_vs_Actual
# — ผลของเพื่อน vs actual  (เห็นชัดว่าผิดที่ตรงไหน)
# ══════════════════════════════════════════════════════════════
cat("\n── Sheet 1: Friend_vs_Actual ─────────────────────────\n")

# Build from friend_raw + actual from our test set
# actual is canonical (from friend's own saved splits used for training)
actual_df <- s1$test_set %>%
  mutate(Row_id = if ("row_id" %in% names(s1$test_set)) row_id else seq_len(n())) %>%
  select(Row_id, Actual = tumor_type) %>%
  mutate(Actual = as.character(Actual))

build_sheet1 <- function(friend_raw, actual_df) {
  if (is.null(friend_raw)) return(data.frame())

  merged <- friend_raw %>%
    left_join(actual_df, by = "Row_id") %>%
    mutate(
      Actual            = coalesce(Actual, Actual_in_Friend_xlsx),
      Friend_Correct    = Actual == Friend_Predicted,
      Result            = if_else(
        Friend_Correct,
        "Correct",
        paste0("Wrong  |  Actual: ", Actual, "  →  Predicted: ", Friend_Predicted)
      )
    ) %>%
    select(Model, Row_id, Actual, Friend_Predicted, Friend_Correct, Result) %>%
    arrange(Model, Row_id)

  merged
}

sh1 <- build_sheet1(friend_raw, actual_df)

# If friend_raw failed, fall back to comparison_step1
if (nrow(sh1) == 0 && !is.null(comparison_step1)) {
  sh1 <- comparison_step1 %>%
    select(Model, Row_id, Actual,
           Friend_Predicted,
           Friend_Correct) %>%
    mutate(
      Result = if_else(
        Friend_Correct,
        "Correct",
        paste0("Wrong  |  Actual: ", Actual, "  →  Predicted: ", Friend_Predicted)
      )
    ) %>%
    arrange(Model, Row_id)
}

cat(sprintf("  Rows: %d\n", nrow(sh1)))
if (nrow(sh1) > 0) {
  n_wrong <- sum(!sh1$Friend_Correct, na.rm=TRUE)
  cat(sprintf("  Correct: %d | Wrong: %d (%.1f%%)\n",
              sum(sh1$Friend_Correct, na.rm=TRUE), n_wrong,
              100 * n_wrong / nrow(sh1)))
}

# ══════════════════════════════════════════════════════════════
# SHEET 2: Ours_vs_Friend
# — ผลของเรา vs ผลเพื่อน  (ตรงกันไหม)
# ══════════════════════════════════════════════════════════════
cat("\n── Sheet 2: Ours_vs_Friend ───────────────────────────\n")

build_sheet2 <- function(our_test, friend_raw, comparison_step1) {
  # Try to build from comparison_step1 first (already merged)
  if (!is.null(comparison_step1) && nrow(comparison_step1) > 0 &&
      "Friend_Predicted" %in% names(comparison_step1)) {
    df <- comparison_step1 %>%
      select(Model, Row_id,
             Our_Predicted,
             Friend_Predicted,
             Agree = Prediction_Agree) %>%
      mutate(
        Agree  = as.logical(Agree),
        Result = if_else(Agree,
                         "Agree",
                         paste0("Differ  |  Ours: ", Our_Predicted,
                                "  |  Friend: ", Friend_Predicted))
      ) %>%
      arrange(Model, Row_id)
    return(df)
  }

  # Fallback: merge manually
  if (is.null(friend_raw)) return(data.frame())
  ours_sub <- our_test %>%
    select(Model, Row_id, Our_Predicted = Predicted)
  merged <- ours_sub %>%
    inner_join(friend_raw %>% select(Model, Row_id, Friend_Predicted),
               by = c("Model", "Row_id")) %>%
    mutate(
      Agree  = Our_Predicted == Friend_Predicted,
      Result = if_else(Agree,
                       "Agree",
                       paste0("Differ  |  Ours: ", Our_Predicted,
                              "  |  Friend: ", Friend_Predicted))
    ) %>%
    arrange(Model, Row_id)
  merged
}

sh2 <- build_sheet2(our_test, friend_raw, comparison_step1)
cat(sprintf("  Rows: %d\n", nrow(sh2)))
if (nrow(sh2) > 0) {
  n_agree <- sum(sh2$Agree, na.rm=TRUE)
  cat(sprintf("  Agree: %d | Differ: %d (%.1f%% agreement)\n",
              n_agree, nrow(sh2) - n_agree,
              100 * n_agree / nrow(sh2)))
}

# ══════════════════════════════════════════════════════════════
# SHEET 3: Ours_vs_Friend_vs_Actual
# — เรา | เพื่อน | actual — เห็นผลรวม
# ══════════════════════════════════════════════════════════════
cat("\n── Sheet 3: Ours_vs_Friend_vs_Actual ────────────────\n")

build_sheet3 <- function(our_test, friend_raw, comparison_step1) {
  if (!is.null(comparison_step1) && nrow(comparison_step1) > 0 &&
      "Friend_Predicted" %in% names(comparison_step1)) {
    df <- comparison_step1 %>%
      select(Model, Row_id, Actual,
             Our_Predicted,
             Friend_Predicted,
             Our_Correct,
             Friend_Correct) %>%
      mutate(
        Our_Correct    = as.logical(Our_Correct),
        Friend_Correct = as.logical(Friend_Correct),
        Outcome = case_when(
           Our_Correct &  Friend_Correct ~ "Both Correct",
           Our_Correct & !Friend_Correct ~ "Only Ours Correct",
          !Our_Correct &  Friend_Correct ~ "Only Friend Correct",
          TRUE                           ~ "Both Wrong"
        )
      ) %>%
      arrange(Model, Row_id)
    return(df)
  }

  if (is.null(friend_raw)) return(data.frame())

  actual_df <- our_test %>% distinct(Row_id, Actual)
  ours_sub  <- our_test %>% select(Model, Row_id, Our_Predicted = Predicted, Our_Correct = Correct)

  merged <- ours_sub %>%
    left_join(actual_df, by = "Row_id") %>%
    left_join(friend_raw %>% select(Model, Row_id, Friend_Predicted), by = c("Model","Row_id")) %>%
    mutate(
      Our_Correct    = as.logical(Our_Correct),
      Friend_Correct = Actual == Friend_Predicted,
      Outcome = case_when(
         Our_Correct &  Friend_Correct ~ "Both Correct",
         Our_Correct & !Friend_Correct ~ "Only Ours Correct",
        !Our_Correct &  Friend_Correct ~ "Only Friend Correct",
        TRUE                           ~ "Both Wrong"
      )
    ) %>%
    select(Model, Row_id, Actual, Our_Predicted, Friend_Predicted,
           Our_Correct, Friend_Correct, Outcome) %>%
    arrange(Model, Row_id)
  merged
}

sh3 <- build_sheet3(our_test, friend_raw, comparison_step1)
cat(sprintf("  Rows: %d\n", nrow(sh3)))
if (nrow(sh3) > 0) {
  print(table(sh3$Outcome))
}

# ══════════════════════════════════════════════════════════════
# SHEET 4: SingleModels_vs_Ensemble
# — 4 single model + ensemble ในแต่ละ row
# ══════════════════════════════════════════════════════════════
cat("\n── Sheet 4: SingleModels_vs_Ensemble ────────────────\n")

build_sheet4 <- function(pred_wide, model_names) {
  # pred_wide columns: Row_id | Actual | {M}_Pred | {M}_Correct | ... | HardVote_Pred | HardVote_Correct | SoftVote_Pred | SoftVote_Correct
  pred_cols    <- paste0(model_names, "_Pred")
  correct_cols <- paste0(model_names, "_Correct")

  present_pred    <- intersect(pred_cols,    names(pred_wide))
  present_correct <- intersect(correct_cols, names(pred_wide))

  # Build clean wide table
  df <- pred_wide %>%
    select(
      Row_id, Actual,
      any_of(c(rbind(pred_cols, correct_cols))),   # interleave pred + correct per model
      HardVote_Pred, HardVote_Correct,
      SoftVote_Pred, SoftVote_Correct,
      N_SingleModels_Correct
    ) %>%
    rename_with(~ gsub("_Pred$",    "",        .x),
                matches("_Pred$")) %>%
    rename_with(~ gsub("_Correct$", "_OK",     .x),
                matches("_Correct$")) %>%
    mutate(
      N_Correct_Single = N_SingleModels_OK,
      # Highlight improvement: ensemble correct but not all singles
      HV_Better_Than_All = HardVote_OK & (N_SingleModels_OK < length(present_pred)),
      SV_Better_Than_All = SoftVote_OK & (N_SingleModels_OK < length(present_pred)),
      # Ensemble wrong but some singles right
      HV_Worse_Than_Some = !HardVote_OK & (N_SingleModels_OK > 0),
      SV_Worse_Than_Some = !SoftVote_OK & (N_SingleModels_OK > 0)
    ) %>%
    select(-N_SingleModels_OK) %>%
    arrange(Row_id)

  df
}

sh4 <- build_sheet4(pred_wide, MODEL_NAMES)
cat(sprintf("  Rows: %d\n", nrow(sh4)))
if (nrow(sh4) > 0 && "HardVote_OK" %in% names(sh4)) {
  cat(sprintf("  HardVote correct: %d/%d (%.1f%%)\n",
              sum(sh4$HardVote_OK, na.rm=TRUE), nrow(sh4),
              100 * mean(sh4$HardVote_OK, na.rm=TRUE)))
  cat(sprintf("  SoftVote correct: %d/%d (%.1f%%)\n",
              sum(sh4$SoftVote_OK, na.rm=TRUE), nrow(sh4),
              100 * mean(sh4$SoftVote_OK, na.rm=TRUE)))
}

# ══════════════════════════════════════════════════════════════
# SHEET 5: Actual_vs_Ensemble
# — actual vs ensemble (Hard Vote + Soft Vote)
# ══════════════════════════════════════════════════════════════
cat("\n── Sheet 5: Actual_vs_Ensemble ──────────────────────\n")

build_sheet5 <- function(pred_wide) {
  df <- pred_wide %>%
    select(Row_id, Actual,
           HardVote_Predicted = HardVote_Pred,
           SoftVote_Predicted = SoftVote_Pred,
           HardVote_Correct,
           SoftVote_Correct) %>%
    mutate(
      Both_Correct = HardVote_Correct & SoftVote_Correct,
      Both_Wrong   = !HardVote_Correct & !SoftVote_Correct,
      HV_SV_Agree  = HardVote_Predicted == SoftVote_Predicted,
      HV_Result    = if_else(
        HardVote_Correct, "Correct",
        paste0("Wrong  |  Actual: ", Actual, "  →  Predicted: ", HardVote_Predicted)
      ),
      SV_Result    = if_else(
        SoftVote_Correct, "Correct",
        paste0("Wrong  |  Actual: ", Actual, "  →  Predicted: ", SoftVote_Predicted)
      )
    ) %>%
    arrange(Row_id)
  df
}

sh5 <- build_sheet5(pred_wide)
cat(sprintf("  Rows: %d\n", nrow(sh5)))
if (nrow(sh5) > 0) {
  cat(sprintf("  HardVote: %d/%d correct (%.1f%%)\n",
              sum(sh5$HardVote_Correct, na.rm=TRUE), nrow(sh5),
              100 * mean(sh5$HardVote_Correct, na.rm=TRUE)))
  cat(sprintf("  SoftVote: %d/%d correct (%.1f%%)\n",
              sum(sh5$SoftVote_Correct, na.rm=TRUE), nrow(sh5),
              100 * mean(sh5$SoftVote_Correct, na.rm=TRUE)))
  cat(sprintf("  Both correct: %d | Both wrong: %d\n",
              sum(sh5$Both_Correct, na.rm=TRUE),
              sum(sh5$Both_Wrong,   na.rm=TRUE)))
}

# ══════════════════════════════════════════════════════════════
# BUILD WORKBOOK
# ══════════════════════════════════════════════════════════════
cat("\n=== Writing workbook ===\n")
wb <- createWorkbook()

# ── Sheet 1 ──────────────────────────────────────────────────
write_sheet(wb, "1_Friend_vs_Actual", sh1, h_blue)
if (nrow(sh1) > 0) {
  colour_rows(wb, "1_Friend_vs_Actual", sh1, "Friend_Correct", s_correct, s_wrong)
}
cat("  Written: 1_Friend_vs_Actual\n")

# ── Sheet 2 ──────────────────────────────────────────────────
write_sheet(wb, "2_Ours_vs_Friend", sh2, h_green)
if (nrow(sh2) > 0) {
  colour_rows(wb, "2_Ours_vs_Friend", sh2, "Agree", s_agree, s_disagree)
}
cat("  Written: 2_Ours_vs_Friend\n")

# ── Sheet 3 ──────────────────────────────────────────────────
write_sheet(wb, "3_Ours_vs_Friend_vs_Actual", sh3, h_blue)
if (nrow(sh3) > 0) {
  colour_rows_by_value(wb, "3_Ours_vs_Friend_vs_Actual", sh3, "Outcome", list(
    "Both Correct"        = s_both_ok,
    "Both Wrong"          = s_both_bad,
    "Only Ours Correct"   = s_only_ours,
    "Only Friend Correct" = s_only_friend
  ))
}
cat("  Written: 3_Ours_vs_Friend_vs_Actual\n")

# ── Sheet 4 ──────────────────────────────────────────────────
write_sheet(wb, "4_SingleModels_vs_Ensemble", sh4, h_purple)
if (nrow(sh4) > 0) {
  # Colour based on N_Correct_Single vs ensemble
  hv_ok_col  <- which(names(sh4) == "HardVote_OK")
  sv_ok_col  <- which(names(sh4) == "SoftVote_OK")
  for (i in seq_len(nrow(sh4))) {
    n_single <- sh4$N_Correct_Single[i]
    hv_ok    <- isTRUE(sh4$HardVote_OK[i])
    sv_ok    <- isTRUE(sh4$SoftVote_OK[i])
    n_models <- length(MODEL_NAMES)
    if (n_single == n_models && hv_ok && sv_ok) {
      # All correct
      addStyle(wb, "4_SingleModels_vs_Ensemble", s_correct,
               rows = i+1, cols = 1:ncol(sh4), stack = TRUE)
    } else if (n_single == 0 && !hv_ok && !sv_ok) {
      # All wrong
      addStyle(wb, "4_SingleModels_vs_Ensemble", s_wrong,
               rows = i+1, cols = 1:ncol(sh4), stack = TRUE)
    } else if ((hv_ok || sv_ok) && n_single < n_models) {
      # Ensemble improved
      addStyle(wb, "4_SingleModels_vs_Ensemble", s_only_ours,
               rows = i+1, cols = 1:ncol(sh4), stack = TRUE)
    }
  }
}
cat("  Written: 4_SingleModels_vs_Ensemble\n")

# ── Sheet 5 ──────────────────────────────────────────────────
write_sheet(wb, "5_Actual_vs_Ensemble", sh5, h_purple)
if (nrow(sh5) > 0) {
  for (i in seq_len(nrow(sh5))) {
    hv <- isTRUE(sh5$HardVote_Correct[i])
    sv <- isTRUE(sh5$SoftVote_Correct[i])
    sty <- if (hv && sv)   s_correct  else
           if (!hv && !sv) s_wrong    else
           s_agree   # one right one wrong → light blue
    addStyle(wb, "5_Actual_vs_Ensemble", sty,
             rows = i+1, cols = 1:ncol(sh5), stack = TRUE)
  }
}
cat("  Written: 5_Actual_vs_Ensemble\n")

# ── Save ───────────────────────────────────────────────────────
saveWorkbook(wb, OUT_FILE, overwrite = TRUE)

cat("\n╔══════════════════════════════════════════════════════╗\n")
cat("║  QUICK COMPARISON REPORT COMPLETE                     ║\n")
cat("╚══════════════════════════════════════════════════════╝\n")
cat(sprintf("  File: %s\n\n", OUT_FILE))

cat("  Colour legend:\n")
cat("    Sheet 1 — Green = Friend Correct | Red = Friend Wrong\n")
cat("    Sheet 2 — Blue  = Ours & Friend Agree | Amber = Differ\n")
cat("    Sheet 3 — Green = Both Correct | Red = Both Wrong\n")
cat("              Teal  = Only Ours Correct | Yellow = Only Friend Correct\n")
cat("    Sheet 4 — Green = All models correct | Red = All wrong\n")
cat("              Teal  = Ensemble improved over single models\n")
cat("    Sheet 5 — Green = Both ensembles correct | Red = Both wrong\n")
cat("              Blue  = Hard vs Soft disagree\n")
