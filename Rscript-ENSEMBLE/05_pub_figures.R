# ============================================================
#  05_pub_figures.R — Publication-Quality Figures
#  cfDNA Multi-Class Ensemble Analysis
#
#  Output sets:
#    Web : 600 px  (standard)  |  1200 px (high-res)
#    PDF : 85 mm  half-page    |  170 mm  full-page  @ 300 dpi
#  Font  : Times New Roman
#
#  Reads from:
#    results/01_single_model/step1_results.rds
#    results/02_ensemble/ensemble_model.rds
#  Writes to:
#    results/pub_figures/web/   (*_web_std.png, *_web_hi.png)
#    results/pub_figures/pdf/   (*_pdf_half.png, *_pdf_full.png)
# ============================================================

suppressPackageStartupMessages({
  library(tidyverse)
  library(ggplot2)
  library(scales)
  library(pROC)
  library(gridExtra)
})

cat("╔══════════════════════════════════════════════════════╗\n")
cat("║  05_pub_figures — Publication Figure Generator       ║\n")
cat("╚══════════════════════════════════════════════════════╝\n\n")

# ── 1. Font Setup ─────────────────────────────────────────────
TNR <- tryCatch({
  if (requireNamespace("extrafont", quietly = TRUE)) {
    suppressMessages(extrafont::loadfonts(device = "win", quiet = TRUE))
    cat("Font: Times New Roman (via extrafont)\n")
  } else {
    cat("Font: Times New Roman (system)\n")
  }
  "Times New Roman"
}, error = function(e) {
  cat("Font: serif (fallback — install extrafont for Times New Roman)\n")
  "serif"
})

# ── 2. Paths (คำนวณจากตำแหน่งโฟลเดอร์ — see 00_config.R) ─────
local({
  cand <- c("Rscript-ENSEMBLE/00_config.R", "00_config.R", "../Rscript-ENSEMBLE/00_config.R")
  hit  <- cand[file.exists(cand)]
  if (!length(hit))
    stop("ไม่พบ 00_config.R — setwd() ไปที่ repo root หรือโฟลเดอร์ Rscript-ENSEMBLE ก่อน", call. = FALSE)
  p <- normalizePath(hit[1], winslash = "/")
  assign(".ENSEMBLE_CFG_PATH", p, envir = globalenv())
  sys.source(p, envir = globalenv())
})

ENS_RDS <- STEP2_RDS
WEB_DIR <- file.path(PUBFIG_DIR, "web")
PDF_DIR <- file.path(PUBFIG_DIR, "pdf")

dir.create(WEB_DIR, recursive = TRUE, showWarnings = FALSE)
dir.create(PDF_DIR, recursive = TRUE, showWarnings = FALSE)
cat(sprintf("Web output : %s\n", WEB_DIR))
cat(sprintf("PDF output : %s\n\n", PDF_DIR))

# ── 3. Load Data ──────────────────────────────────────────────
cat("=== Loading results ===\n")

if (!file.exists(STEP1_RDS)) stop("step1_results.rds not found — run 01_single_model_analysis.R first")
if (!file.exists(ENS_RDS))   stop("ensemble_model.rds not found — run 02_ensemble_multi.R first")

s1 <- readRDS(STEP1_RDS)
overall_metrics   <- s1$overall_metrics
per_class_metrics <- s1$per_class_metrics
all_results       <- s1$all_results
CLASS_LEVELS      <- s1$CLASS_LEVELS
N_CLASSES         <- s1$N_CLASSES
agreement_df      <- if (!is.null(s1$agreement_df)) s1$agreement_df else data.frame()
test_set          <- s1$test_set

ens <- readRDS(ENS_RDS)
full_comparison   <- ens$full_comparison
full_per_class    <- ens$full_per_class
pred_wide         <- ens$pred_wide
all_6_preds       <- ens$all_6_preds
hard_vote_prob    <- ens$hard_vote_prob
soft_vote_prob    <- ens$soft_vote_prob
hard_vote_class   <- ens$hard_vote_class
soft_vote_class   <- ens$soft_vote_class
top3_names        <- ens$top3_names

y_test <- all_results[[names(all_results)[1]]][["Test"]]$y_true
cat(sprintf("Classes: %s | Test rows: %d\n\n",
            paste(CLASS_LEVELS, collapse = ", "), length(y_test)))

# ── 4. Theme Helpers ──────────────────────────────────────────
# `...` = theme() overrides ที่ส่งมาจาก call site
# ต้อง merge กับ default ด้วย modifyList ก่อน แล้วค่อย do.call(theme, ...)
# ถ้าส่ง `...` เข้า theme() ตรง ๆ แล้วชื่อชนกับ default (เช่น plot.title)
# R จะ error: 'formal argument "plot.title" matched by multiple actual arguments'
.merge_theme <- function(defaults, ...) {
  do.call(theme, modifyList(defaults, list(...)))
}

pub_theme <- function(bs, ...) {
  theme_bw(base_family = TNR, base_size = bs) +
    .merge_theme(list(
      plot.title        = element_text(face = "bold", size = bs + 1),
      plot.subtitle     = element_text(size = bs - 1, color = "gray40"),
      axis.title        = element_text(size = bs),
      axis.text         = element_text(size = bs - 1),
      legend.text       = element_text(size = bs - 1),
      legend.title      = element_text(size = bs, face = "bold"),
      strip.text        = element_text(size = bs - 1, face = "bold"),
      strip.background  = element_rect(fill = "gray95", colour = "gray70"),
      panel.grid.minor  = element_blank()
    ), ...)
}

pub_theme_tile <- function(bs, ...) {
  theme_minimal(base_family = TNR, base_size = bs) +
    .merge_theme(list(
      plot.title       = element_text(face = "bold", size = bs + 1),
      plot.subtitle    = element_text(size = bs - 1, color = "gray40"),
      axis.title       = element_text(size = bs),
      axis.text        = element_text(size = bs - 1),
      legend.text      = element_text(size = bs - 1),
      legend.title     = element_text(size = bs, face = "bold"),
      panel.grid       = element_blank(),
      panel.border     = element_rect(colour = "black", fill = NA, linewidth = 0.6)
    ), ...)
}

# ── 5. pub_save() — Save 4 versions of a figure ───────────────
# plt_full  : ggplot / grob  (base_size = 9, full-page design)
# plt_half  : ggplot / grob  (base_size = 7, half-page design); NULL → reuse plt_full
# name      : filename stem  (no extension, no path)
# ar_full   : height/width ratio for full-page  (170 mm)
# ar_half   : height/width ratio for half-page  (85 mm);  NULL → ar_full
pub_save <- function(plt_full, name,
                     ar_full = 0.65,
                     plt_half = NULL,
                     ar_half  = NULL) {

  if (is.null(plt_half)) plt_half <- plt_full
  if (is.null(ar_half))  ar_half  <- ar_full

  # ── Web standard: 600 px wide ──
  h_ws <- max(300L, round(600 * ar_full))
  suppressMessages(
    ggsave(file.path(WEB_DIR, paste0(name, "_web_std.png")),
           plt_full, width = 600, height = h_ws, units = "px", dpi = 96)
  )

  # ── Web high-res: 1200 px wide ──
  h_wh <- max(400L, round(1200 * ar_full))
  suppressMessages(
    ggsave(file.path(WEB_DIR, paste0(name, "_web_hi.png")),
           plt_full, width = 1200, height = h_wh, units = "px", dpi = 96)
  )

  # ── PDF half-page: 85 mm @ 300 dpi ──
  h_ph <- min(225L, max(40L, round(85 * ar_half)))
  suppressMessages(
    ggsave(file.path(PDF_DIR, paste0(name, "_pdf_half.png")),
           plt_half, width = 85, height = h_ph, units = "mm", dpi = 300)
  )

  # ── PDF full-page: 170 mm @ 300 dpi ──
  h_pf <- min(225L, max(60L, round(170 * ar_full)))
  suppressMessages(
    ggsave(file.path(PDF_DIR, paste0(name, "_pdf_full.png")),
           plt_full, width = 170, height = h_pf, units = "mm", dpi = 300)
  )

  cat(sprintf("  [saved] %-40s  web:%dx%d / %dx%d | pdf:85x%dmm / 170x%dmm\n",
              name, 600L, h_ws, 1200L, h_wh, h_ph, h_pf))
}

# ── 6. Shared colour palettes ─────────────────────────────────
MODEL_COLORS <- c(KNN = "#4E79A7", SVM = "#F28E2B", XGB = "#E15759", RF  = "#76B7B2")
ENS_COLORS   <- c("Single"    = "#60A5FA",
                  "Hard Vote" = "#F87171",
                  "Soft Vote" = "#34D399")

# =============================================================
#  STEP 1 FIGURES — Single Model Analysis
# =============================================================
cat("\n── Step 1: Single Model Figures ──────────────────────\n")

# ── S1-01: Overall metrics bar (Test Set, 6 metrics × 4 models) ──
make_s1_01 <- function(bs) {
  dat <- overall_metrics %>%
    filter(Set == "Test") %>%
    select(Model, Accuracy, Macro_AUC, Macro_F1,
           Macro_Sensitivity, Macro_Specificity, Macro_Precision) %>%
    pivot_longer(-Model, names_to = "Metric", values_to = "Value") %>%
    mutate(
      Metric = recode(Metric,
        "Macro_AUC"         = "Macro AUC",
        "Macro_F1"          = "Macro F1",
        "Macro_Sensitivity" = "Sensitivity",
        "Macro_Specificity" = "Specificity",
        "Macro_Precision"   = "Precision"),
      Metric = factor(Metric,
        levels = c("Accuracy","Macro AUC","Macro F1",
                   "Sensitivity","Specificity","Precision"))
    )

  ggplot(dat, aes(x = Model, y = Value, fill = Model)) +
    geom_col(width = 0.65, colour = "white", linewidth = 0.3) +
    geom_text(aes(label = sprintf("%.3f", Value)),
              vjust = -0.4, size = bs * 0.27, family = TNR) +
    facet_wrap(~ Metric, scales = "free_y", ncol = 3) +
    scale_fill_manual(values = MODEL_COLORS) +
    scale_y_continuous(labels = number_format(accuracy = 0.01),
                       expand = expansion(mult = c(0, 0.14))) +
    labs(x = NULL, y = "Value") +
    pub_theme(bs, legend.position = "none",
              axis.text.x = element_text(angle = 30, hjust = 1))
}
pub_save(make_s1_01(9), "S1_01_overall_metrics",
         ar_full = 0.68, plt_half = make_s1_01(7), ar_half = 0.80)

# ── S1-02: Metrics trend across Train → Val → Test ──
make_s1_02 <- function(bs) {
  dat <- overall_metrics %>%
    mutate(Set = factor(Set, levels = c("Train","Validation","Test")))

  p_acc <- ggplot(dat, aes(x = Set, y = Accuracy, group = Model, colour = Model)) +
    geom_line(linewidth = 0.9) +
    geom_point(size = 2.2) +
    geom_text(aes(label = sprintf("%.3f", Accuracy)),
              vjust = -0.7, size = bs * 0.25, family = TNR) +
    scale_colour_manual(values = MODEL_COLORS) +
    scale_y_continuous(limits = c(0, 1.08),
                       labels = number_format(accuracy = 0.01)) +
    labs(title = "(a) Accuracy", x = "Dataset", y = "Accuracy", colour = NULL) +
    pub_theme(bs, legend.position = "bottom")

  p_auc <- ggplot(dat, aes(x = Set, y = Macro_AUC, group = Model, colour = Model)) +
    geom_line(linewidth = 0.9) +
    geom_point(size = 2.2) +
    geom_text(aes(label = sprintf("%.3f", Macro_AUC)),
              vjust = -0.7, size = bs * 0.25, family = TNR) +
    scale_colour_manual(values = MODEL_COLORS) +
    scale_y_continuous(limits = c(0, 1.08),
                       labels = number_format(accuracy = 0.01)) +
    labs(title = "(b) Macro AUC (OvR)", x = "Dataset", y = "Macro AUC", colour = NULL) +
    pub_theme(bs, legend.position = "bottom")

  g <- arrangeGrob(p_acc, p_auc, nrow = 1)
  g
}
pub_save(make_s1_02(9), "S1_02_metrics_trend",
         ar_full = 0.50, plt_half = make_s1_02(7), ar_half = 0.60)

# ── S1-03: Per-class AUC heatmap (Test Set) ──
make_s1_03 <- function(bs) {
  dat <- per_class_metrics %>%
    filter(Set == "Test") %>%
    select(Model, Class, AUC)

  ggplot(dat, aes(x = Class, y = Model, fill = AUC)) +
    geom_tile(colour = "white", linewidth = 0.7) +
    geom_text(aes(label = sprintf("%.3f", AUC)),
              size = bs * 0.30, fontface = "bold", family = TNR) +
    scale_fill_gradient(low = "#FEF9C3", high = "#1E40AF",
                        na.value = "grey80", limits = c(0, 1), name = "AUC") +
    labs(x = "Tumor Class", y = "Model") +
    pub_theme_tile(bs,
      axis.text.x = element_text(angle = 30, hjust = 1))
}
ar_hm <- (N_CLASSES * 0.22 + 0.15)   # scale with number of classes
pub_save(make_s1_03(9), "S1_03_perclass_auc_heatmap",
         ar_full = ar_hm, plt_half = make_s1_03(7), ar_half = ar_hm * 1.1)

# ── S1-04: Per-class F1 heatmap (Test Set) ──
make_s1_04 <- function(bs) {
  dat <- per_class_metrics %>%
    filter(Set == "Test") %>%
    select(Model, Class, F1)

  ggplot(dat, aes(x = Class, y = Model, fill = F1)) +
    geom_tile(colour = "white", linewidth = 0.7) +
    geom_text(aes(label = sprintf("%.3f", F1)),
              size = bs * 0.30, fontface = "bold", family = TNR) +
    scale_fill_gradient(low = "#FEE2E2", high = "#166534",
                        na.value = "grey80", limits = c(0, 1), name = "F1") +
    labs(x = "Tumor Class", y = "Model") +
    pub_theme_tile(bs,
      axis.text.x = element_text(angle = 30, hjust = 1))
}
pub_save(make_s1_04(9), "S1_04_perclass_f1_heatmap",
         ar_full = ar_hm, plt_half = make_s1_04(7), ar_half = ar_hm * 1.1)

# ── S1-05: Confusion matrices — 4 models combined 2×2 panel ──
make_cm_single <- function(nm, bs) {
  cm_tbl <- as.data.frame(all_results[[nm]][["Test"]]$cm$table)
  ggplot(cm_tbl, aes(x = Reference, y = Prediction, fill = Freq)) +
    geom_tile(colour = "white", linewidth = 0.5) +
    geom_text(aes(label = Freq),
              size = bs * 0.32, fontface = "bold", family = TNR) +
    scale_fill_gradient(low = "#EFF6FF", high = "#1D4ED8", name = "n") +
    labs(title = nm, x = "Reference", y = "Prediction") +
    pub_theme_tile(bs,
      axis.text.x = element_text(angle = 30, hjust = 1),
      legend.key.size = unit(0.35, "cm"),
      plot.title = element_text(face = "bold", size = bs + 1, hjust = 0.5))
}

make_s1_05 <- function(bs) {
  panels <- lapply(names(all_results), make_cm_single, bs = bs)
  labels <- paste0("(", letters[seq_along(panels)], ")")
  arrangeGrob(grobs = panels, nrow = 2, ncol = 2)
}
pub_save(make_s1_05(9), "S1_05_confusion_matrices",
         ar_full = 0.85, plt_half = make_s1_05(7), ar_half = 1.0)

# ── S1-06: Model ranking by Macro-AUC (Test Set) ──
make_s1_06 <- function(bs) {
  dat <- overall_metrics %>%
    filter(Set == "Test") %>%
    arrange(desc(Macro_AUC)) %>%
    mutate(Rank = row_number())

  ggplot(dat, aes(x = reorder(Model, Macro_AUC), y = Macro_AUC, fill = Model)) +
    geom_col(width = 0.6) +
    geom_text(aes(label = sprintf("%.4f  (#%d)", Macro_AUC, Rank)),
              hjust = -0.08, size = bs * 0.28, family = TNR, fontface = "bold") +
    scale_fill_manual(values = MODEL_COLORS) +
    scale_y_continuous(limits = c(0, 1.18),
                       labels = number_format(accuracy = 0.01)) +
    coord_flip() +
    labs(x = NULL, y = "Macro AUC (OvR)") +
    pub_theme(bs, legend.position = "none")
}
pub_save(make_s1_06(9), "S1_06_model_ranking",
         ar_full = 0.55, plt_half = make_s1_06(7), ar_half = 0.65)

# ── S1-07: Per-class metrics bar (Sens / Spec / Prec / F1, by model) ──
make_s1_07 <- function(bs) {
  dat <- per_class_metrics %>%
    filter(Set == "Test") %>%
    pivot_longer(cols = c(Sensitivity, Specificity, Precision, F1),
                 names_to = "Metric", values_to = "Value")

  ggplot(dat, aes(x = Class, y = Value, fill = Metric)) +
    geom_col(position = "dodge", width = 0.72) +
    geom_text(aes(label = sprintf("%.2f", Value)),
              position = position_dodge(0.72),
              vjust = -0.3, size = bs * 0.22, family = TNR) +
    facet_wrap(~ Model, ncol = 2) +
    scale_fill_brewer(palette = "Set1") +
    scale_y_continuous(limits = c(0, 1.16),
                       labels = number_format(accuracy = 0.01)) +
    labs(x = "Tumor Class", y = "Value", fill = "Metric") +
    pub_theme(bs,
      axis.text.x = element_text(angle = 30, hjust = 1),
      legend.position = "bottom")
}
pub_save(make_s1_07(9), "S1_07_perclass_metrics_bar",
         ar_full = 0.85, plt_half = make_s1_07(7), ar_half = 1.0)

# ── S1-08: Agreement vs friend (conditional) ──
if (!is.null(agreement_df) && nrow(agreement_df) > 0 &&
    all(c("Model","Our_Accuracy","Friend_Accuracy","Agreement_Rate") %in% names(agreement_df))) {

  make_s1_08 <- function(bs) {
    dat <- agreement_df %>%
      select(Model, Our_Accuracy, Friend_Accuracy, Agreement_Rate) %>%
      pivot_longer(-Model, names_to = "Metric", values_to = "Value") %>%
      mutate(Metric = recode(Metric,
        "Our_Accuracy"    = "Our Accuracy",
        "Friend_Accuracy" = "Friend Accuracy",
        "Agreement_Rate"  = "Agreement Rate"))

    ggplot(dat, aes(x = Model, y = Value, fill = Metric)) +
      geom_col(position = "dodge", width = 0.65) +
      geom_text(aes(label = sprintf("%.3f", Value)),
                position = position_dodge(0.65),
                vjust = -0.35, size = bs * 0.26, family = TNR) +
      scale_fill_manual(values = c("Our Accuracy"    = "#3B82F6",
                                   "Friend Accuracy" = "#F97316",
                                   "Agreement Rate"  = "#10B981")) +
      scale_y_continuous(limits = c(0, 1.14),
                         labels = number_format(accuracy = 0.01)) +
      labs(x = NULL, y = "Rate", fill = NULL) +
      pub_theme(bs, legend.position = "bottom")
  }
  pub_save(make_s1_08(9), "S1_08_agreement_vs_friend",
           ar_full = 0.60, plt_half = make_s1_08(7), ar_half = 0.72)
} else {
  cat("  [skip] S1_08 — agreement data not available\n")
}

# =============================================================
#  STEP 2 FIGURES — Ensemble Analysis
# =============================================================
cat("\n── Step 2: Ensemble Figures ───────────────────────────\n")

# Attach ensemble type label
full_comparison_lab <- full_comparison %>%
  mutate(
    EnsType = case_when(
      grepl("Hard",  Model) ~ "Hard Vote",
      grepl("Soft",  Model) ~ "Soft Vote",
      TRUE                   ~ "Single"
    ),
    Model_Short = gsub(" \\(Top3\\)", "", Model)
  )

# ── S2-01: Full comparison bar — 6 models × 6 metrics ──
make_s2_01 <- function(bs) {
  dat <- full_comparison_lab %>%
    select(Model_Short, EnsType, Accuracy, Macro_AUC, Macro_F1,
           Macro_Sensitivity, Macro_Specificity, Macro_Precision) %>%
    pivot_longer(-c(Model_Short, EnsType), names_to = "Metric", values_to = "Value") %>%
    mutate(
      Metric = recode(Metric,
        "Macro_AUC"         = "Macro AUC",
        "Macro_F1"          = "Macro F1",
        "Macro_Sensitivity" = "Sensitivity",
        "Macro_Specificity" = "Specificity",
        "Macro_Precision"   = "Precision"),
      Metric = factor(Metric,
        levels = c("Accuracy","Macro AUC","Macro F1",
                   "Sensitivity","Specificity","Precision"))
    )

  ggplot(dat, aes(x = Model_Short, y = Value, fill = EnsType)) +
    geom_col(width = 0.65, colour = "white", linewidth = 0.3) +
    geom_text(aes(label = sprintf("%.3f", Value)),
              vjust = -0.35, size = bs * 0.22, family = TNR) +
    facet_wrap(~ Metric, scales = "free_y", ncol = 3) +
    scale_fill_manual(values = ENS_COLORS) +
    scale_y_continuous(labels = number_format(accuracy = 0.01),
                       expand = expansion(mult = c(0, 0.14))) +
    labs(x = NULL, y = "Value", fill = "Model Type") +
    pub_theme(bs,
      axis.text.x = element_text(angle = 40, hjust = 1),
      legend.position = "top")
}
pub_save(make_s2_01(9), "S2_01_full_comparison_bar",
         ar_full = 0.72, plt_half = make_s2_01(7), ar_half = 0.85)

# ── S2-02: Macro-AUC ranking — all 6 models ──
make_s2_02 <- function(bs) {
  dat <- full_comparison_lab %>%
    arrange(desc(Macro_AUC)) %>%
    mutate(Rank = row_number())

  ggplot(dat, aes(x = reorder(Model_Short, Macro_AUC), y = Macro_AUC,
                  fill = EnsType)) +
    geom_col(width = 0.6) +
    geom_text(aes(label = sprintf("%.4f  (#%d)", Macro_AUC, Rank)),
              hjust = -0.07, size = bs * 0.27, family = TNR, fontface = "bold") +
    scale_fill_manual(values = ENS_COLORS) +
    scale_y_continuous(limits = c(0, 1.18),
                       labels = number_format(accuracy = 0.01)) +
    coord_flip() +
    labs(x = NULL, y = "Macro AUC (OvR)", fill = "Model Type") +
    pub_theme(bs, legend.position = "bottom")
}
pub_save(make_s2_02(9), "S2_02_macro_auc_ranking",
         ar_full = 0.60, plt_half = make_s2_02(7), ar_half = 0.70)

# ── S2-03: Ensemble confusion matrices (HardVote + SoftVote) combined ──
make_ens_cm <- function(pred_class, prob_mat, label, bs) {
  cm_obj <- caret::confusionMatrix(
    factor(pred_class, levels = CLASS_LEVELS),
    factor(y_test,     levels = CLASS_LEVELS)
  )
  cm_tbl <- as.data.frame(cm_obj$table)
  ggplot(cm_tbl, aes(x = Reference, y = Prediction, fill = Freq)) +
    geom_tile(colour = "white", linewidth = 0.5) +
    geom_text(aes(label = Freq),
              size = bs * 0.32, fontface = "bold", family = TNR) +
    scale_fill_gradient(low = "#ECFDF5", high = "#065F46", name = "n") +
    labs(title = label, x = "Reference", y = "Prediction") +
    pub_theme_tile(bs,
      axis.text.x = element_text(angle = 30, hjust = 1),
      legend.key.size = unit(0.35, "cm"),
      plot.title = element_text(face = "bold", size = bs + 1, hjust = 0.5))
}

suppressPackageStartupMessages(library(caret))
make_s2_03 <- function(bs) {
  p_hv <- make_ens_cm(hard_vote_class, hard_vote_prob, "(a) Hard Vote", bs)
  p_sv <- make_ens_cm(soft_vote_class, soft_vote_prob, "(b) Soft Vote", bs)
  arrangeGrob(p_hv, p_sv, nrow = 1)
}
ar_cm <- max(0.55, N_CLASSES * 0.18 + 0.10)
pub_save(make_s2_03(9), "S2_03_ensemble_cm",
         ar_full = ar_cm, plt_half = make_s2_03(7), ar_half = ar_cm * 1.15)

# ── S2-04: Per-class AUC heatmap — all 6 models ──
make_s2_04 <- function(bs) {
  dat <- full_per_class %>%
    mutate(Model = gsub(" \\(Top3\\)", "", Model)) %>%
    select(Model, Class, AUC)

  ggplot(dat, aes(x = Class, y = Model, fill = AUC)) +
    geom_tile(colour = "white", linewidth = 0.7) +
    geom_text(aes(label = sprintf("%.3f", AUC)),
              size = bs * 0.28, fontface = "bold", family = TNR) +
    scale_fill_gradient(low = "#FEF3C7", high = "#1E3A5F",
                        na.value = "grey80", limits = c(0, 1), name = "AUC") +
    labs(x = "Tumor Class", y = NULL) +
    pub_theme_tile(bs,
      axis.text.x = element_text(angle = 30, hjust = 1))
}
ar_hm6 <- (6 * 0.16 + 0.10)
pub_save(make_s2_04(9), "S2_04_all6_auc_heatmap",
         ar_full = ar_hm6, plt_half = make_s2_04(7), ar_half = ar_hm6 * 1.1)

# ── S2-05: Per-class F1 heatmap — all 6 models ──
make_s2_05 <- function(bs) {
  dat <- full_per_class %>%
    mutate(Model = gsub(" \\(Top3\\)", "", Model)) %>%
    select(Model, Class, F1)

  ggplot(dat, aes(x = Class, y = Model, fill = F1)) +
    geom_tile(colour = "white", linewidth = 0.7) +
    geom_text(aes(label = sprintf("%.3f", F1)),
              size = bs * 0.28, fontface = "bold", family = TNR) +
    scale_fill_gradient(low = "#FEE2E2", high = "#166534",
                        na.value = "grey80", limits = c(0, 1), name = "F1") +
    labs(x = "Tumor Class", y = NULL) +
    pub_theme_tile(bs,
      axis.text.x = element_text(angle = 30, hjust = 1))
}
pub_save(make_s2_05(9), "S2_05_all6_f1_heatmap",
         ar_full = ar_hm6, plt_half = make_s2_05(7), ar_half = ar_hm6 * 1.1)

# ── S2-06: Ensemble accuracy by agreement level ──
make_s2_06 <- function(bs) {
  dat <- pred_wide %>%
    select(Actual,
           HardVote_Correct, SoftVote_Correct, N_SingleModels_Correct) %>%
    pivot_longer(cols = c(HardVote_Correct, SoftVote_Correct),
                 names_to = "Ensemble", values_to = "Correct") %>%
    mutate(Ensemble = recode(Ensemble,
      "HardVote_Correct" = "Hard Vote",
      "SoftVote_Correct" = "Soft Vote"))

  ggplot(dat, aes(x = factor(N_SingleModels_Correct), fill = Correct)) +
    geom_bar(position = "fill", width = 0.7) +
    facet_wrap(~ Ensemble) +
    scale_fill_manual(values = c("TRUE" = "#22C55E", "FALSE" = "#EF4444"),
                      labels = c("TRUE" = "Correct", "FALSE" = "Incorrect")) +
    scale_y_continuous(labels = percent_format()) +
    labs(x = "Number of Correct Single Models (out of 4)",
         y = "Proportion", fill = NULL) +
    pub_theme(bs, legend.position = "bottom")
}
pub_save(make_s2_06(9), "S2_06_vote_agreement",
         ar_full = 0.55, plt_half = make_s2_06(7), ar_half = 0.65)

# ── S2-07: Performance profile — all 6 models (faceted) ──
make_s2_07 <- function(bs) {
  dat <- full_comparison_lab %>%
    select(Model_Short, EnsType, Accuracy, Macro_AUC, Macro_F1,
           Macro_Sensitivity, Macro_Specificity, Macro_Precision) %>%
    pivot_longer(-c(Model_Short, EnsType), names_to = "Metric", values_to = "Value") %>%
    mutate(Metric = gsub("Macro_", "", Metric),
           Metric = factor(Metric,
             levels = c("Accuracy","AUC","F1","Sensitivity","Specificity","Precision")))

  ggplot(dat, aes(x = Metric, y = Value, fill = EnsType)) +
    geom_col(width = 0.72) +
    geom_text(aes(label = sprintf("%.3f", Value)),
              vjust = -0.3, size = bs * 0.20, family = TNR) +
    facet_wrap(~ Model_Short, ncol = 3) +
    scale_fill_manual(values = ENS_COLORS, guide = "none") +
    scale_y_continuous(limits = c(0, 1.12),
                       labels = number_format(accuracy = 0.01)) +
    labs(x = NULL, y = "Value") +
    pub_theme(bs,
      axis.text.x = element_text(angle = 40, hjust = 1))
}
pub_save(make_s2_07(9), "S2_07_performance_profile",
         ar_full = 0.72, plt_half = make_s2_07(7), ar_half = 0.85)

# ── S2-08: OvR ROC curves — all 6 models, faceted by class ──
cat("  Building ROC curves (all 6 models)...\n")

model_pred_list <- c(
  lapply(names(all_results), function(nm) {
    list(label    = nm,
         pred_cls = all_results[[nm]][["Test"]]$pred_class,
         prob_mat = all_results[[nm]][["Test"]]$prob_mat)
  }),
  list(
    list(label    = "Hard Vote",
         pred_cls = hard_vote_class,
         prob_mat = hard_vote_prob),
    list(label    = "Soft Vote",
         pred_cls = soft_vote_class,
         prob_mat = soft_vote_prob)
  )
)

roc_df <- tryCatch({
  bind_rows(lapply(model_pred_list, function(r) {
    bind_rows(lapply(CLASS_LEVELS, function(cls) {
      bin <- as.numeric(y_test == cls)
      if (length(unique(bin)) < 2) return(NULL)
      col <- if (cls %in% colnames(r$prob_mat)) r$prob_mat[, cls] else
               as.numeric(r$pred_cls == cls)
      roc_obj <- tryCatch(pROC::roc(bin, col, quiet = TRUE), error = function(e) NULL)
      if (is.null(roc_obj)) return(NULL)
      data.frame(
        Model = r$label, Class = cls,
        FPR   = 1 - roc_obj$specificities,
        TPR   = roc_obj$sensitivities,
        AUC   = round(as.numeric(pROC::auc(roc_obj)), 4),
        stringsAsFactors = FALSE
      )
    }))
  }))
}, error = function(e) {
  cat(sprintf("  [warn] ROC computation failed: %s\n", e$message))
  NULL
})

if (!is.null(roc_df) && nrow(roc_df) > 0) {
  roc_labels <- roc_df %>%
    distinct(Model, Class, AUC) %>%
    mutate(label = sprintf("%s (AUC=%.3f)", Model, AUC))

  make_s2_08 <- function(bs) {
    auc_ann <- roc_df %>%
      group_by(Model, Class) %>%
      summarise(AUC = unique(AUC), .groups = "drop") %>%
      group_by(Class) %>%
      arrange(desc(AUC)) %>%
      mutate(y_pos = 0.12 + (row_number() - 1) * (bs / 80))

    ggplot(roc_df, aes(x = FPR, y = TPR, colour = Model, group = Model)) +
      geom_line(linewidth = 0.8) +
      geom_abline(slope = 1, intercept = 0,
                  linetype = "dashed", colour = "grey55", linewidth = 0.4) +
      facet_wrap(~ Class, ncol = min(3L, N_CLASSES)) +
      scale_colour_brewer(palette = "Dark2") +
      scale_x_continuous(labels = number_format(accuracy = 0.1)) +
      scale_y_continuous(labels = number_format(accuracy = 0.1)) +
      labs(x = "False Positive Rate  (1 − Specificity)",
           y = "True Positive Rate  (Sensitivity)",
           colour = NULL) +
      pub_theme(bs, legend.position = "bottom",
                legend.key.width = unit(1.2, "cm"))
  }
  pub_save(make_s2_08(9), "S2_08_roc_curves",
           ar_full = 0.52, plt_half = make_s2_08(7), ar_half = 0.62)
} else {
  cat("  [skip] S2_08 — ROC curve data could not be computed\n")
}

# ── Summary ───────────────────────────────────────────────────
cat("\n╔══════════════════════════════════════════════════════╗\n")
cat("║  Publication figures saved                            ║\n")
cat(sprintf("║  Web  : %-43s║\n", WEB_DIR))
cat(sprintf("║  PDF  : %-43s║\n", PDF_DIR))
cat("║  Suffixes:                                            ║\n")
cat("║    _web_std.png  — 600 px  (web standard)            ║\n")
cat("║    _web_hi.png   — 1200 px (web high-res)            ║\n")
cat("║    _pdf_half.png — 85 mm @ 300 dpi  (half page)      ║\n")
cat("║    _pdf_full.png — 170 mm @ 300 dpi (full page)      ║\n")
cat("╚══════════════════════════════════════════════════════╝\n")
