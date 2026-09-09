# Rscript-ENSEMBLE — cfDNA Multi-Class Ensemble

Ensemble layer ที่ต่อยอดจาก single models ใน `Rscript-MAIN/`
จำแนก **3 คลาส**: `Normal` / `Brain.tumors` / `Sarcomas`

---

## แนวทาง

1. โหลด **pre-trained single models 4 ตัว** จาก `model/multi/` (KNN, SVM, XGBoost, RF — caret, 10-fold CV × 3 repeats)
2. ประเมินทั้ง 4 ตัวบน **train / validation / test split ชุดเดิม** (ไม่ re-split ใหม่ เพื่อให้เทียบกับผล single model ได้ตรง ๆ)
3. เรียงตาม **Macro-AUC บน test set** → เลือก **Top 3**
4. สร้าง ensemble 2 แบบจาก Top 3
   - **Hard Vote** — majority vote, tie-break ด้วยโมเดลที่ AUC สูงสุด
   - **Soft Vote** — เฉลี่ย class probability
5. เทียบ 6 โมเดล (4 single + 2 ensemble) ทั้งภาพรวม ราย class และ row-by-row ทุกแถวใน test set

---

## ไฟล์

| ไฟล์ | ทำอะไร | Output |
|---|---|---|
| `00_config.R` | path ทั้งหมด — คำนวณจากตำแหน่งโฟลเดอร์นี้เอง ไม่มี absolute path | — |
| `01_single_model_analysis.R` | predict ด้วย 4 โมเดลบน train/val/test → Accuracy, Kappa, Macro-AUC/F1, per-class Sens/Spec/Prec/F1/AUC + เทียบ row-by-row กับผล single model ต้นทาง | `results/01_single_model/` |
| `02_ensemble_multi.R` | Top 3 → Hard Vote + Soft Vote → เทียบ 6 โมเดล + ROC | `results/02_ensemble/` |
| `03_combined_report.R` | รวมทุกอย่างเป็น Excel ไฟล์เดียวหลายชีต (color-coded) | `results/combined_report_multi.xlsx` |
| `04_quick_comparison.R` | สรุปย่อ 5 ชีตสำหรับดู/แชร์ | `results/quick_comparison_multi.xlsx` |
| `05_pub_figures.R` | รูปคุณภาพตีพิมพ์ — web 600/1200 px, PDF 85/170 mm @ 300 dpi | `results/pub_figures/` |
| `run_all.R` | รัน `01`→`05` ตามลำดับ | — |

**ลำดับสำคัญ**: `02` อ่าน `step1_results.rds` จาก `01`; `03`–`05` อ่านทั้ง `step1_results.rds` และ `ensemble_model.rds`

---

## ข้อมูล

**ข้อมูลผู้ป่วยไม่ได้ commit ลง repo นี้** (`data/` อยู่ใน `.gitignore`)
ต้องเตรียมเองก่อนรัน — เลือกทางใดทางหนึ่ง:

**ทาง A — วางไฟล์ในโฟลเดอร์ default**

```
Rscript-ENSEMBLE/data/
├── ML_multi_train.rds
├── ML_multi_val.rds
├── ML_multi_test.rds
├── ML_multi_encodeddf.rds
└── reference/
    ├── ML_predictions_multi.xlsx
    ├── ML_ConfusionMetrics_multi.xlsx
    └── {knn,svm,xgb,rf}_tuned_metrics_multi_seed.rds
```

**ทาง B — ชี้ไปที่โฟลเดอร์อื่นด้วย env var (ไม่ต้องก๊อปไฟล์)**

```r
Sys.setenv(CFDNA_DATA_DIR = "D:/.../Multi_Tumor_Type/Dataframe")
Sys.setenv(CFDNA_REF_DIR  = "D:/.../Multi_Tumor_Type/result")
```

ถ้าไฟล์ไม่ครบ สคริปต์จะหยุดพร้อมบอกชื่อไฟล์ที่หาย (`check_inputs()` ใน `00_config.R`)

---

## วิธีรัน

### 1. ติดตั้ง R packages

```r
install.packages(c(
  "tidyverse", "caret", "pROC", "openxlsx",
  "ggplot2", "gridExtra", "scales",
  "randomForest", "xgboost", "e1071", "ranger", "kernlab"
))
```

`extrafont` เพิ่มเติม (ไม่บังคับ) — ใช้ฝัง Times New Roman ใน `05_pub_figures.R`
ถ้าไม่มีจะ fallback เป็น serif อัตโนมัติ

### 2. รัน

จาก repo root:

```bash
Rscript Rscript-ENSEMBLE/run_all.R
```

หรือทีละสเต็ป `01` → `05` ก็ได้ ทั้งจาก repo root และจากในโฟลเดอร์นี้

---

## Features

- **Numeric** — cfDNA fragment features คัดด้วย ANOVA (p < 0.05)
- **Categorical** — motif peaks คัดด้วย Fisher's exact test (p < 0.05)
- one-hot encode + z-score standardize แล้วก่อนบันทึกลง `data/`

Target: `tumor_type` (คลาส `Others` ถูกตัดออก)
Split: train 60% / validation 10% / test 30% แบบ stratified ตาม tumor type

---

## Reproducibility

- `set.seed(123)` ใน `01_`, `set.seed(42)` ใน `02_`
- ไม่มีการเทรนโมเดลใหม่ — ใช้ pre-trained `.rds` ใน `model/multi/` ผลจึงคงที่ทุกครั้ง
- รันผ่านครบทั้ง pipeline บน R 4.3.3 (Windows)

ผลบน test set (96 samples):

| Rank | Model | Accuracy | Macro-AUC | Macro-F1 |
|---|---|---|---|---|
| 1 | Ensemble HardVote (Top3) | 0.8438 | 0.9504 | 0.7588 |
| 2 | Ensemble SoftVote (Top3) | 0.8333 | 0.9504 | 0.7477 |
| 3 | RF | 0.8542 | 0.9499 | 0.7790 |
| 4 | XGB | 0.8021 | 0.9318 | 0.6931 |
| 5 | KNN | 0.8125 | 0.8836 | 0.7095 |
| 6 | SVM | 0.7396 | 0.8509 | 0.5270 |

Top 3 ที่ถูกเลือก: **RF > XGB > KNN** (tie-break = RF)
