# Machine Learning Analysis

This directory contains the R scripts used for cfDNA-based machine learning analysis. The workflow starts from an already generated cfDNA feature dataframe and performs data preparation, statistical feature selection, feature encoding, dataset splitting, machine learning model training, hyperparameter tuning, and final model evaluation.

Four machine learning algorithms are evaluated:

* K-Nearest Neighbors (KNN)
* Support Vector Machine (SVM)
* Extreme Gradient Boosting (XGBoost)
* Random Forest (RF)

---

## 1. Classification Settings

The machine learning analysis consists of two binary classification settings and one multiclass classification setting.

### 1.1 Overall Binary Classification (`normal`)

The overall binary classification distinguishes:

```text
Healthy vs All Tumors
```

The suffix `normal` is a project filename convention. It does **not** represent a separate classification type.

### 1.2 Tumor-Specific Binary Classification (`ext`)

The tumor-specific binary classification consists of two separate comparisons:

```text
Healthy vs Brain Tumors
Healthy vs Sarcomas
```

### 1.3 Multiclass Classification (`multi`)

The multiclass classification distinguishes three groups:

```text
Healthy vs Brain Tumors vs Sarcomas
```

Therefore, the project contains:

| Classification setting        | Classes                                      |
| ----------------------------- | -------------------------------------------- |
| Overall binary (`normal`)     | Healthy vs All Tumors                        |
| Tumor-specific binary (`ext`) | Healthy vs Brain Tumors; Healthy vs Sarcomas |
| Multiclass (`multi`)          | Healthy vs Brain Tumors vs Sarcomas          |

---

## 2. Workflow Overview

The machine learning workflow is organized into several sequential stages:

```text
Input Feature Dataframe
        |
        v
Data Preparation
        |
        v
Statistical Feature Selection
        |
        v
Feature Encoding and Standardization
        |
        v
Train / Validation / Test Split
        |
        v
Model Training
        |
        v
Hyperparameter Tuning
        |
        v
Validation
        |
        v
Final Test Evaluation
        |
        v
RDS Result Files
```

The workflow is implemented separately for the `normal`, `ext`, and `multi` classification settings.

---

# 3. R Scripts

## 3.1 Setting and Workflow Control

The `ML_setting_*` scripts act as the main entry points for each classification setting. They load and combine the input RDS files, perform initial data preparation, and call the downstream feature-selection, encoding, dataset, model, and result scripts.

| Filename              | Job                                                                                                                                                                                                                              | Main output                                                                  |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `ML_setting_normal.R` | Controls the overall binary classification workflow. Loads the feature data, combines the input RDS files, removes `sample_id`, standardizes tumor-type labels, removes the `Others` category, and calls the downstream scripts. | Prepared dataset and complete overall binary classification workflow         |
| `ML_setting_ext.R`    | Controls the tumor-specific binary classification workflow for Brain Tumors and Sarcomas.                                                                                                                                        | Prepared datasets and complete tumor-specific binary classification workflow |
| `ML_setting_multi.R`  | Controls the multiclass classification workflow for Healthy, Brain Tumors, and Sarcomas.                                                                                                                                         | Prepared dataset and complete multiclass classification workflow             |

Input RDS files are read and sorted using `gtools::mixedsort()` before being combined.

---

# 4. Feature Selection

Feature selection is performed before machine learning model training to identify features associated with the classification target.

The statistical method depends on the type of predictor and classification setting.

### Numerical features

For binary classification:

* Independent two-sample t-test

For multiclass classification:

* One-way ANOVA

### Categorical features

* Fisher's exact test

Features with:

```text
p < 0.05
```

are considered statistically significant and retained for downstream modelling.

Statistical feature importance is visualized using:

```text
-log10(p-value)
```

A larger `-log10(p-value)` represents a smaller p-value and stronger statistical evidence of an association with the classification target.

Random Forest Gini importance is also calculated to provide a model-based measure of feature importance. The feature-importance Random Forest uses:

```text
ntree = 500
```

---

# 5. Feature Encoding and Standardization

After feature selection, the selected features are transformed into a format suitable for machine learning.

The preprocessing workflow includes:

1. One-hot encoding of categorical features
2. Removal of zero-variance predictors
3. Centering of numerical predictors
4. Scaling of numerical predictors

The `recipes` package is used to construct the preprocessing workflow.

`row_id` is retained for tracking observations through the workflow but is not used as a model predictor.

For binary classification, the target variable is `tumor_label`.

For multiclass classification, the target variable is `tumor_type`.

---

# 6. Dataset Preparation

The dataset scripts prepare the model-ready data and divide observations into training, validation, and testing datasets.

A fixed random seed is used:

```r
set.seed(123)
```

This allows the same data split to be reproduced.

`row_id` is retained in the datasets so that predictions can be traced back to the original observations. However, `row_id` is explicitly excluded from the model predictors.

| Filename              | Job                                                                    | Main output                                |
| --------------------- | ---------------------------------------------------------------------- | ------------------------------------------ |
| `ML_dataset_normal.R` | Prepares and splits the overall binary classification dataset.         | Training, validation, and testing datasets |
| `ML_dataset_ext.R`    | Prepares and splits the tumor-specific binary classification datasets. | Training, validation, and testing datasets |
| `ML_dataset_multi.R`  | Prepares and splits the multiclass classification dataset.             | Training, validation, and testing datasets |

The scripts also generate class-distribution visualizations to inspect the distribution of the target classes across the datasets.

---

# 7. Machine Learning Models

Four machine learning algorithms are evaluated using the `caret` training framework.

The training procedure uses repeated 10-fold cross-validation with three repeats:

```r
trainControl(
  method = "repeatedcv",
  number = 10,
  repeats = 3,
  classProbs = TRUE,
  allowParallel = TRUE
)
```

Accuracy is used as the primary metric for model tuning.

Each model is evaluated sequentially on:

```text
Training set
      |
      v
Validation set
      |
      v
Independent test set
```

---

## 7.1 K-Nearest Neighbors

KNN classifies an observation according to the classes of nearby observations in the feature space.

The model is trained through the `caret` framework using:

```r
caret::train(..., method = "knn")
```

| Filename          | Job                                                                                                                                   | Main output                                                                                          |
| ----------------- | ------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `ML_KNN_normal.R` | Trains and tunes KNN for Healthy vs All Tumors. Generates predictions and ROC curves for the training, validation, and test datasets. | KNN model, tuned KNN model, predictions, confusion matrices, ROC/AUC results, and evaluation metrics |
| `ML_KNN_ext.R`    | Trains and tunes KNN for Healthy vs Brain Tumors and Healthy vs Sarcomas.                                                             | KNN models, tuned models, predictions, ROC/AUC results, and evaluation metrics                       |
| `ML_KNN_multi.R`  | Trains and tunes KNN for Healthy vs Brain Tumors vs Sarcomas. Performs multiclass ROC/AUC analysis and one-vs-rest ROC analysis.      | KNN model, tuned model, multiclass predictions, ROC/AUC results, and evaluation metrics              |

---

## 7.2 Support Vector Machine

A radial-basis-function Support Vector Machine is used to model potentially nonlinear relationships between the selected cfDNA features and the classification target.

The model is trained through `caret` using:

```r
caret::train(..., method = "svmRadial")
```

The radial SVM implementation is provided through `kernlab`.

| Filename          | Job                                                                                                                                | Main output                                                                                          |
| ----------------- | ---------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| `ML_SVM_normal.R` | Trains and tunes radial SVM for Healthy vs All Tumors. Generates predictions and ROC curves for training, validation, and testing. | SVM model, tuned SVM model, predictions, confusion matrices, ROC/AUC results, and evaluation metrics |
| `ML_SVM_ext.R`    | Trains and tunes radial SVM for Healthy vs Brain Tumors and Healthy vs Sarcomas.                                                   | SVM models, tuned models, predictions, ROC/AUC results, and evaluation metrics                       |
| `ML_SVM_multi.R`  | Trains and tunes radial SVM for Healthy vs Brain Tumors vs Sarcomas. Performs multiclass and one-vs-rest ROC/AUC analysis.         | SVM model, tuned model, multiclass predictions, ROC/AUC results, and evaluation metrics              |

---

## 7.3 XGBoost

XGBoost is a gradient boosting algorithm that builds an ensemble of decision trees sequentially, with each new tree improving the errors of previous trees.

The model is trained through `caret` using:

```r
caret::train(..., method = "xgbTree")
```

The underlying implementation is provided by the `xgboost` package.

| Filename              | Job                                                                                                                     | Main output                                                                                                  |
| --------------------- | ----------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| `ML_XGBoost_normal.R` | Trains and tunes XGBoost for Healthy vs All Tumors.                                                                     | XGBoost model, tuned XGBoost model, predictions, confusion matrices, ROC/AUC results, and evaluation metrics |
| `ML_XGBoost_ext.R`    | Trains and tunes XGBoost for Healthy vs Brain Tumors and Healthy vs Sarcomas.                                           | XGBoost models, tuned models, predictions, ROC/AUC results, and evaluation metrics                           |
| `ML_XGBoost_multi.R`  | Trains and tunes XGBoost for Healthy vs Brain Tumors vs Sarcomas. Performs multiclass and one-vs-rest ROC/AUC analysis. | XGBoost model, tuned model, multiclass predictions, ROC/AUC results, and evaluation metrics                  |

---

## 7.4 Random Forest

Random Forest is an ensemble tree-based classification algorithm that builds multiple decision trees and combines their predictions.

The Random Forest models in the machine-learning workflow are trained through `caret` using:

```r
caret::train(..., method = "ranger")
```

Random Forest feature importance in the feature-selection stage is separately calculated using the `randomForest` package and Mean Decrease in Gini.

| Filename         | Job                                                                                                                           | Main output                                                                                                |
| ---------------- | ----------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| `ML_RF_normal.R` | Trains and tunes Random Forest for Healthy vs All Tumors.                                                                     | Random Forest model, tuned model, predictions, confusion matrices, ROC/AUC results, and evaluation metrics |
| `ML_RF_ext.R`    | Trains and tunes Random Forest for Healthy vs Brain Tumors and Healthy vs Sarcomas.                                           | Random Forest models, tuned models, predictions, ROC/AUC results, and evaluation metrics                   |
| `ML_RF_multi.R`  | Trains and tunes Random Forest for Healthy vs Brain Tumors vs Sarcomas. Performs multiclass and one-vs-rest ROC/AUC analysis. | Random Forest model, tuned model, multiclass predictions, ROC/AUC results, and evaluation metrics          |

---

# 8. Model Calling and Result Saving

The `ML_Calling_*` scripts coordinate the four machine learning models for each classification setting.

They call the corresponding KNN, SVM, XGBoost, and Random Forest functions and save the resulting models, tuned models, predictions, and evaluation metrics.

| Filename              | Job                                                                                                    | Main output                                                                                                      |
| --------------------- | ------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------- |
| `ML_Calling_normal.R` | Runs the four models for Healthy vs All Tumors and saves their training, validation, and test results. | KNN, SVM, XGBoost, and RF model objects, tuned models, metrics, predictions, and RDS result files                |
| `ML_Calling_ext.R`    | Runs the four models for Healthy vs Brain Tumors and Healthy vs Sarcomas.                              | Model objects, tuned models, metrics, predictions, and RDS result files for tumor-specific binary classification |
| `ML_Calling_multi.R`  | Runs the four models for Healthy vs Brain Tumors vs Sarcomas.                                          | Model objects, tuned models, multiclass metrics, predictions, and RDS result files                               |

The saved RDS objects contain the information required to inspect model performance without retraining the models.

---

# 9. R Package Dependencies

The following packages are used across the workflow.

| Package        | Job in this work                                                                                                                                        |
| -------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `caret`        | Main machine-learning framework for model training, hyperparameter tuning, repeated cross-validation, prediction, and confusion-matrix-based evaluation |
| `recipes`      | Feature preprocessing, including one-hot encoding, zero-variance filtering, centering, and scaling                                                      |
| `dplyr`        | Data manipulation, filtering, transformation, and dataset preparation                                                                                   |
| `gtools`       | Natural sorting of RDS filenames before combining input datasets                                                                                        |
| `forcats`      | Factor and categorical-variable handling during dataset preparation                                                                                     |
| `class`        | K-Nearest Neighbors implementation used by the KNN model                                                                                                |
| `e1071`        | Supporting package for Support Vector Machine functionality                                                                                             |
| `kernlab`      | Radial-basis-function SVM implementation used through `caret::train(method = "svmRadial")`                                                              |
| `xgboost`      | XGBoost implementation used by the XGBoost model                                                                                                        |
| `randomForest` | Random Forest implementation used for feature-importance analysis and Mean Decrease in Gini                                                             |
| `pROC`         | ROC curve and AUC calculation for binary and multiclass classification                                                                                  |
| `ggplot2`      | Visualization of feature importance, class distributions, ROC curves, and other analysis results                                                        |
| `gridExtra`    | Arrangement of multiple plots                                                                                                                           |
| `GGally`       | Exploratory and pairwise data visualization                                                                                                             |
| `reshape2`     | Data reshaping for analysis and visualization                                                                                                           |
| `corrplot`     | Correlation matrix visualization                                                                                                                        |
| `Cairo`        | Graphics device support for exported figures                                                                                                            |
| `extrafont`    | Font management for exported figures                                                                                                                    |
| `stats`        | Statistical analysis, including independent t-test, one-way ANOVA, and Fisher's exact test                                                              |

---

# 10. Model Evaluation

Model performance is evaluated using predictions generated on the training, validation, and independent test datasets.

The final reported results are based on the **independent test dataset**.

The 95% confidence interval is reported from the confusion-matrix evaluation and independently verified using the exact binomial method (`binom.test()`).

## Binary Classification Metrics

The following metrics are reported:

* Accuracy
* Precision
* Recall
* Specificity
* F1-score
* AUC
* 95% confidence interval for Accuracy

ROC curves and AUC are calculated using `pROC::roc()`.

## Multiclass Classification Metrics

For multiclass classification, the following metrics are reported:

* Accuracy
* Macro Precision
* Macro Recall
* Macro Specificity
* Macro F1-score
* Macro AUC
* 95% confidence interval for Accuracy

Metrics other than Accuracy are macro-averaged across:

```text
Healthy
Brain Tumors
Sarcomas
```

Multiclass AUC is calculated using `pROC::multiclass.roc()`.

---

# 11. Results

The following tables summarize the final test-set performance of the four machine learning models.

## 11.1 Overall Binary Classification: Healthy vs All Tumors

| Model         | Accuracy | Precision | Recall | Specificity | F1-score |   AUC | Accuracy 95% CI        |
| ------------- | -------: | --------: | -----: | ----------: | -------: | ----: | ------------- |
| KNN           |    0.875 |     0.964 |  0.844 |       0.938 |    0.900 | 0.921 | 0.7918-0.9337 |
| SVM           |    0.885 |     0.965 |  0.859 |       0.938 |    0.909 | 0.965 | 0.8042-0.9414 |
| XGBoost       |    0.896 |     0.966 |  0.875 |       0.938 |    0.918 | 0.941 | 0.8168-0.9489 |
| Random Forest |    0.875 |     0.948 |  0.859 |       0.906 |    0.902 | 0.969 | 0.7918-0.9337 |

## 11.2 Tumor-Specific Binary Classification: Healthy vs Brain Tumors

| Model         | Accuracy | Precision | Recall | Specificity | F1-score |   AUC | Accuracy 95% CI        |
| ------------- | -------: | --------: | -----: | ----------: | -------: | ----: | ------------- |
| KNN           |    0.873 |     0.950 |  0.891 |       0.800 |    0.919 | 0.947 | 0.7795-0.9376 |
| SVM           |    0.886 |     0.983 |  0.875 |       0.933 |    0.926 | 0.924 | 0.7947-0.9466 |
| XGBoost       |    0.873 |     0.950 |  0.891 |       0.800 |    0.919 | 0.957 | 0.7795-0.9376 |
| Random Forest |    0.861 |     0.965 |  0.859 |       0.867 |    0.909 | 0.960 | 0.7645-0.9284 |

## 11.3 Tumor-Specific Binary Classification: Healthy vs Sarcomas

| Model         | Accuracy | Precision | Recall | Specificity | F1-score |   AUC | Accuracy 95% CI        |
| ------------- | -------: | --------: | -----: | ----------: | -------: | ----: | ------------- |
| KNN           |    0.877 |     0.982 |  0.859 |       0.941 |    0.917 | 0.935 | 0.7847-0.9392 |
| SVM           |    0.877 |     0.982 |  0.859 |       0.941 |    0.917 | 0.961 | 0.7847-0.9392 |
| XGBoost       |    0.889 |     0.966 |  0.891 |       0.882 |    0.927 | 0.983 | 0.7995-0.9479 |
| Random Forest |    0.889 |     0.966 |  0.891 |       0.882 |    0.927 | 0.976 | 0.7995-0.9479 |

## 11.4 Multiclass Classification: Healthy vs Brain Tumors vs Sarcomas

All metrics except Accuracy are macro-averaged across the three classes.

| Model         | Accuracy | Macro Precision | Macro Recall | Macro Specificity | Macro F1-score | Macro AUC | Accuracy 95% CI        |
| ------------- | -------: | --------------: | -----------: | ----------------: | -------------: | --------: | ------------- |
| KNN           |    0.813 |           0.695 |        0.732 |             0.919 |          0.713 |     0.838 | 0.7200-0.8849 |
| SVM           |    0.740 |           0.524 |        0.588 |             0.889 |          0.555 |     0.851 | 0.6400-0.8238 |
| XGBoost       |    0.802 |           0.695 |        0.718 |             0.915 |          0.706 |     0.932 | 0.7083-0.8764 |
| Random Forest |    0.854 |           0.763 |        0.801 |             0.935 |          0.782 |     0.950 | 0.7674-0.9179 |

---

# 12. Running the Workflow

## 12.1 Install Required Packages

Install the required packages before running the workflow:

```r
install.packages(c(
  "caret",
  "recipes",
  "dplyr",
  "gtools",
  "forcats",
  "class",
  "e1071",
  "kernlab",
  "xgboost",
  "randomForest",
  "pROC",
  "ggplot2",
  "gridExtra",
  "GGally",
  "reshape2",
  "corrplot",
  "Cairo",
  "extrafont"
))
```

The `stats` package is included with standard R installations and normally does not need to be installed separately.

---

## 12.2 Run a Complete Classification Workflow

Each classification setting has its own main setting script.

### Overall Binary Classification

```r
source("ML_setting_normal.R")
```

This runs:

```text
Healthy vs All Tumors
```

### Tumor-Specific Binary Classification

```r
source("ML_setting_ext.R")
```

This runs:

```text
Healthy vs Brain Tumors
Healthy vs Sarcomas
```

### Multiclass Classification

```r
source("ML_setting_multi.R")
```

This runs:

```text
Healthy vs Brain Tumors vs Sarcomas
```

The setting script controls the downstream workflow and calls the corresponding feature-selection, encoding, dataset, model, and result-calling scripts.

---

# 13. Running Individual Components

The scripts can also be executed separately when users want to inspect or modify a specific part of the workflow.

For example, the overall binary workflow can be executed step by step:

```r
source("ML_feature_normal.R")
source("ML_encode_normal.R")
source("ML_dataset_normal.R")

source("ML_KNN_normal.R")
source("ML_SVM_normal.R")
source("ML_XGBoost_normal.R")
source("ML_RF_normal.R")

source("ML_Calling_normal.R")
```

The equivalent `ext` and `multi` scripts can be used for the other classification settings.

This modular structure allows individual stages to be:

* inspected
* modified
* rerun
* tested independently

without necessarily rerunning the entire workflow.

---

# 14. Input and Output Paths

The input RDS directory and output locations are defined in the corresponding scripts.

When running the repository on another computer, update the paths to match the local directory structure.

The input data should contain the feature variables required by the feature-selection workflow and the appropriate target variables.

The workflow expects:

* `sample_id` to be excluded from model development
* `row_id` to be retained for observation tracking
* `row_id` to be excluded from model predictors
* target variables to be correctly defined
* selected features to be available before encoding
* the same preprocessing procedure to be applied before model training

---

# 15. Output Files

The model-calling scripts save RDS files containing model objects, tuned models, predictions, metrics, and other result objects.

The filename suffix identifies the classification setting:

| Suffix   | Classification setting                                                 |
| -------- | ---------------------------------------------------------------------- |
| `normal` | Overall binary: Healthy vs All Tumors                                  |
| `ext`    | Tumor-specific binary: Healthy vs Brain Tumors and Healthy vs Sarcomas |
| `multi`  | Multiclass: Healthy vs Brain Tumors vs Sarcomas                        |

Typical output files include:

```text
knn_model_*.rds
knn_tune_model_*.rds
knn_tuned_metrics_*.rds
knn_results_*_seed.rds

svm_model_*.rds
svm_tune_model_*.rds
svm_tuned_metrics_*.rds
svm_results_*_seed.rds

xgb_model_*.rds
xgb_tune_model_*.rds
xgb_tuned_metrics_*.rds
xgb_results_*_seed.rds

rf_model_*.rds
rf_tune_model_*.rds
rf_tuned_metrics_*.rds
rf_results_*_seed.rds
```

These files allow trained models and evaluation results to be loaded later without repeating model training.

---

# 16. Reproducibility

The workflow uses:

```r
set.seed(123)
```

for reproducible dataset splitting.

The model-training procedure also uses repeated 10-fold cross-validation with three repeats.

To reproduce the analysis, use the same:

* input feature dataframe
* feature-selection criteria
* preprocessing procedure
* dataset split seed
* model tuning settings
* software and package versions

---

# 17. Summary

The `Rscript-ML` workflow provides a modular machine learning pipeline for cfDNA-based tumor classification.

The analysis includes:

```text
Feature Dataframe
      |
      v
Statistical Feature Selection
      |
      v
One-Hot Encoding
      |
      v
Centering and Scaling
      |
      v
Train / Validation / Test Split
      |
      v
KNN / SVM / XGBoost / Random Forest
      |
      v
Hyperparameter Tuning
      |
      v
Validation
      |
      v
Independent Test Evaluation
```

Three classification settings are evaluated:

* **Overall binary:** Healthy vs All Tumors
* **Tumor-specific binary:** Healthy vs Brain Tumors and Healthy vs Sarcomas
* **Multiclass:** Healthy vs Brain Tumors vs Sarcomas

The final model evaluation reports Accuracy, Precision, Recall, Specificity, F1-score, AUC, and Accuracy confidence intervals, with macro-averaging applied to multiclass performance metrics.
