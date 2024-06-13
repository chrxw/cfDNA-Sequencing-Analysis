# Load required library
library(caret)
library(gridExtra)

# -------------------------------------------------------------------------#

# Function to identify and print zero variance columns
remove_zero_variance_columns <- function(df) {
  # Check for numeric columns only
  numeric_cols <- sapply(df, is.numeric)
  
  # Calculate variance only for numeric columns
  zero_var_columns <- sapply(df[, numeric_cols], function(col) var(col, na.rm = TRUE) == 0)
  zero_var_col_names <- names(df[, numeric_cols])[zero_var_columns]
  
  if (length(zero_var_col_names) > 0) {
    print(paste("Zero variance columns:", paste(zero_var_col_names, collapse = ", ")))
  } else {
    print("No zero variance columns found.")
  }
  
  return(df)
}

processed_dataframe <- remove_zero_variance_columns(processed_dataframe)

# Split Dataset
split_data <- function(data, train_prop, test_prop) {
  repeat {
  data <- data[sample(nrow(data)), ]
  
  # Calculate the number of training samples (as an integer)
  train_rows <- round(nrow(data) * train_prop)
  
  # Split data into two sets
  train_data <- data[1:train_rows, ]
  test_data <- data[(train_rows + 1):nrow(data), ]
  
  # Check if any constant variables remain in any set
  if (all(sapply(list(train_data, test_data), function(df) all(sapply(df, function(x) length(unique(x)) > 1))))) {
    break
  }
  
  return(list(train = train_data, test = test_data))
  }
}

# Set seed for reproducibility
set.seed(42)

# Define proportions
initial_train_prop <- 0.8
final_train_prop <- 0.875
test_prop <- 0.2
val_prop <- 1 - final_train_prop

# Separate the data into two classes: MAIN
tumor_data <- subset(processed_dataframe, tumor_label == "tumor")
no_tumor_data <- subset(processed_dataframe, tumor_label == "no_tumor")

# Split each class into initial training and testing sets
tumor_splits <- split_data(tumor_data, initial_train_prop)
no_tumor_splits <- split_data(no_tumor_data, initial_train_prop)

initial_training_set <- rbind(tumor_splits$train, no_tumor_splits$train)
testing_set <- rbind(tumor_splits$test, no_tumor_splits$test)

tumor_data2 <- subset(initial_training_set, tumor_label == "tumor")
no_tumor_data2 <- subset(initial_training_set, tumor_label == "no_tumor")

tumor_splits2 <- split_data(tumor_data2, final_train_prop)
no_tumor_splits2 <- split_data(no_tumor_data2, final_train_prop)

training_set <- rbind(tumor_splits2$train, no_tumor_splits2$train)
validation_set <- rbind(tumor_splits2$test, no_tumor_splits2$test)

# Factor
training_set$tumor_label <- as.factor(training_set$tumor_label)
testing_set$tumor_label <- as.factor(testing_set$tumor_label)
validation_set$tumor_label <- as.factor(validation_set$tumor_label)

# Separate predictors (features) and target variable
X_train <- training_set[, !names(training_set) %in% c("tumor_label")]
y_train <- training_set$tumor_label

X_test <- testing_set[, !names(testing_set) %in% c("tumor_label")]
y_test <- testing_set$tumor_label

X_val <- validation_set[, !names(validation_set) %in% c("tumor_label")]
y_val <- validation_set$tumor_label

# -------------------------------------------------------------------------#

# Function to create class distribution plot
create_class_distribution_plot <- function(dataset, title, fill_color) {
  class_distribution <- table(dataset$tumor_label)
  class_distribution_df <- as.data.frame(class_distribution)
  names(class_distribution_df) <- c("Class", "Count")
  
  ggplot(class_distribution_df, aes(x = Class, y = Count, fill = Class)) +
    geom_bar(stat = "identity", fill = fill_color) +
    geom_text(aes(label = Count), vjust = -0.5, color = "black", size = 3.5) +
    labs(title = title,
         x = "Class",
         y = "Count") +
    theme_minimal()
}

# Create class distribution plots for each dataset with class ratios
training_plot <- create_class_distribution_plot(training_set, "Training Set", "skyblue")
testing_plot <- create_class_distribution_plot(testing_set, "Testing Set", "orange")
validation_plot <- create_class_distribution_plot(validation_set, "Validation Set", "pink")

# Show the plots
gridExtra::grid.arrange(training_plot, testing_plot, validation_plot, nrow = 1)