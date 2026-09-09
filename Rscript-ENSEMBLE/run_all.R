# ============================================================
#  run_all.R — รัน ensemble pipeline ทั้งหมดตามลำดับ
#
#  วิธีใช้ (รันจาก repo root หรือจากในโฟลเดอร์ Rscript-ENSEMBLE ก็ได้):
#    Rscript Rscript-ENSEMBLE/run_all.R
#
#  ลำดับ: 01 → 02 → 03 → 04 → 05
#  ผลลัพธ์ลงที่ Rscript-ENSEMBLE/results/
# ============================================================

.here <- c("Rscript-ENSEMBLE", ".", "../Rscript-ENSEMBLE")
.here <- .here[file.exists(file.path(.here, "00_config.R"))]
if (!length(.here))
  stop("หา 00_config.R ไม่เจอ — รันจาก repo root หรือจากในโฟลเดอร์ Rscript-ENSEMBLE\n",
       "  working directory ปัจจุบัน: ", getwd(), call. = FALSE)
.here <- .here[1]

STEPS <- c(
  "01_single_model_analysis.R",   # ประเมิน 4 single models บน split เดิม
  "02_ensemble_multi.R",          # Top-3 → Hard Vote + Soft Vote ensemble
  "03_combined_report.R",         # รายงานรวมทุกอย่าง (xlsx ไฟล์เดียว)
  "04_quick_comparison.R",        # รายงานย่อ 5 ชีตสำหรับดู/แชร์
  "05_pub_figures.R"              # รูปคุณภาพตีพิมพ์ (web + pdf)
)

t0 <- Sys.time()
for (s in STEPS) {
  cat("\n\n", strrep("=", 62), "\n  RUN: ", s, "\n", strrep("=", 62), "\n\n", sep = "")
  source(file.path(.here, s), echo = FALSE, encoding = "UTF-8")
}

cat("\n\n✔ เสร็จทั้งหมด — ใช้เวลา ",
    round(as.numeric(difftime(Sys.time(), t0, units = "mins")), 1), " นาที\n",
    "  ผลลัพธ์อยู่ที่: ", normalizePath(file.path(.here, "results")), "\n", sep = "")
