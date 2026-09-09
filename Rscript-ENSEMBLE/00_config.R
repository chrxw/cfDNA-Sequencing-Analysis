# ============================================================
#  00_config.R — Central path configuration
#  cfDNA Multi-Class Ensemble  (Rscript-ENSEMBLE)
#
#  ทุกสคริปต์ในโฟลเดอร์นี้จะ source ไฟล์นี้เป็นอย่างแรก
#  path ทั้งหมดคำนวณจากตำแหน่งของโฟลเดอร์ Rscript-ENSEMBLE เอง
#  จึงย้ายไปวางที่ไหนก็ได้โดยไม่ต้องแก้โค้ด
#
#  โครงสร้างที่คาดหวัง (วางใน repo cfDNA-Sequencing-Analysis):
#    <repo>/Rscript-ENSEMBLE/   ← โฟลเดอร์นี้
#    <repo>/model/multi/        ← pre-trained single models (commit ไว้)
# ============================================================

# ── 1. หา root ───────────────────────────────────────────────
# .ENSEMBLE_CFG_PATH ถูก set โดย bootstrap ที่หัวสคริปต์ 01–05
# ถ้า source ไฟล์นี้ตรง ๆ จะ fallback ไปใช้ working directory
if (!exists(".ENSEMBLE_CFG_PATH")) {
  .cand <- c("Rscript-ENSEMBLE/00_config.R", "00_config.R", "../Rscript-ENSEMBLE/00_config.R")
  .hit  <- .cand[file.exists(.cand)]
  if (!length(.hit))
    stop("หา 00_config.R ไม่เจอ — setwd() ไปที่ repo root หรือที่โฟลเดอร์ Rscript-ENSEMBLE ก่อน\n",
         "  working directory ปัจจุบัน: ", getwd(), call. = FALSE)
  .ENSEMBLE_CFG_PATH <- normalizePath(.hit[1], winslash = "/")
}

SCRIPT_DIR <- dirname(.ENSEMBLE_CFG_PATH)   # <repo>/Rscript-ENSEMBLE
PROJ_ROOT  <- dirname(SCRIPT_DIR)           # <repo>

# ── 2. Input: โมเดล (commit ลง repo) ─────────────────────────
MODEL_DIR <- file.path(PROJ_ROOT, "model", "multi")

MODEL_FILES <- c(
  KNN = "knn_tune_model_multi_seed.rds",
  SVM = "svm_tune_model_multi_seed.rds",
  XGB = "xgb_tune_model_multi_seed.rds",
  RF  = "rf_tune_model_multi_seed.rds"
)

# ── 3. Input: ข้อมูล (ไม่ commit — เป็นข้อมูลผู้ป่วย) ─────────
# ค่า default = Rscript-ENSEMBLE/data/  (อยู่ใน .gitignore)
# ถ้าเก็บข้อมูลไว้ที่อื่น ตั้ง env var แทนได้ ไม่ต้องแก้โค้ด:
#   Sys.setenv(CFDNA_DATA_DIR = "D:/path/to/Dataframe")
#   Sys.setenv(CFDNA_REF_DIR  = "D:/path/to/single_model_result")
DF_DIR  <- Sys.getenv("CFDNA_DATA_DIR", unset = file.path(SCRIPT_DIR, "data"))
REF_DIR <- Sys.getenv("CFDNA_REF_DIR",  unset = file.path(SCRIPT_DIR, "data", "reference"))

DATA_FILES <- c(
  train = "ML_multi_train.rds",
  val   = "ML_multi_val.rds",
  test  = "ML_multi_test.rds",
  full  = "ML_multi_encodeddf.rds"
)

# ชื่อตัวแปรเดิมที่สคริปต์อ้างถึง (ผลของ single model ที่เทรนไว้ก่อน)
BASE_SINGLE         <- REF_DIR
FRIEND_RESULT_DIR   <- REF_DIR
FRIEND_PRED_XLSX    <- file.path(REF_DIR, "ML_predictions_multi.xlsx")
FRIEND_METRICS_XLSX <- file.path(REF_DIR, "ML_ConfusionMetrics_multi.xlsx")

# ── 4. Output (ไม่ commit — สร้างใหม่ได้จากการรัน) ────────────
RESULT_DIR <- file.path(SCRIPT_DIR, "results")
STEP1_DIR  <- file.path(RESULT_DIR, "01_single_model")
STEP2_DIR  <- file.path(RESULT_DIR, "02_ensemble")
PUBFIG_DIR <- file.path(RESULT_DIR, "pub_figures")

STEP1_RDS  <- file.path(STEP1_DIR, "step1_results.rds")   # เขียนโดย 01_, อ่านโดย 02_–05_
STEP2_RDS  <- file.path(STEP2_DIR, "ensemble_model.rds")  # เขียนโดย 02_, อ่านโดย 03_–05_

# ── 5. ตรวจว่าไฟล์ input ครบไหม ───────────────────────────────
check_inputs <- function(need_reference = TRUE) {
  missing <- c(
    file.path(MODEL_DIR, MODEL_FILES)[!file.exists(file.path(MODEL_DIR, MODEL_FILES))],
    file.path(DF_DIR,    DATA_FILES)[!file.exists(file.path(DF_DIR, DATA_FILES))]
  )
  if (need_reference) {
    ref <- c(FRIEND_PRED_XLSX, FRIEND_METRICS_XLSX)
    missing <- c(missing, ref[!file.exists(ref)])
  }
  if (length(missing)) {
    stop("ไฟล์ input ไม่ครบ ", length(missing), " ไฟล์:\n",
         paste0("  - ", missing, collapse = "\n"),
         "\n\nข้อมูลผู้ป่วยไม่ได้ commit ลง repo — ดูหัวข้อ 'ข้อมูล' ใน Rscript-ENSEMBLE/README.md",
         call. = FALSE)
  }
  invisible(TRUE)
}

dir.create(RESULT_DIR, recursive = TRUE, showWarnings = FALSE)

cat("── Config ──\n")
cat("  Repo root  :", PROJ_ROOT,  "\n")
cat("  Model dir  :", MODEL_DIR,  "\n")
cat("  Data  dir  :", DF_DIR,     "\n")
cat("  Result dir :", RESULT_DIR, "\n\n")
