# Load required library
library(caret)
library(gridExtra)
library(dplyr)
library(ggplot2)
library(forcats)

# -------------------------------------------------------------------------#

# Set seed for reproducibility
set.seed(123)

seed_list <- sample(1:1000000, 10000)
seed_counter <- 1

processed_dataframe_ext <- processed_dataframe_ext %>%
  mutate(
    tumor_type = as.character(tumor_type),
    tumor_type = ifelse(
      tumor_type %in% c("Neuroblastoma", "Hematological.malignancies", "Others"),
      "Others",
      tumor_type
    ),
    tumor_label = ifelse(tumor_type == "Normal", "no_tumor", "tumor"),
    row_id = seq_len(n())
  )

processed_dataframe_ext$tumor_type  <- as.factor(processed_dataframe_ext$tumor_type)
processed_dataframe_ext$tumor_label <- as.factor(processed_dataframe_ext$tumor_label)

# ========================= SPLIT TESTING SET ============================ #

split_testing_set <- function(df, test_prop = 0.30, min_test = 1) {
  
  test_list   <- list()
  remain_list <- list()
  
  for (type in levels(df$tumor_type)) {
    
    type_data <- df %>% dplyr::filter(tumor_type == type)
    n <- nrow(type_data)
    
    n_test <- max(min_test, floor(test_prop * n))
    
    if (n_test >= n) {
      test_list[[type]]   <- data.frame()
      remain_list[[type]] <- type_data
      next
    }
    
    set.seed(seed_list[seed_counter])
    seed_counter <<- seed_counter + 1
    
    idx <- caret::createDataPartition(
      type_data$tumor_type,
      p = n_test / n,
      list = FALSE
    )
    
    test_list[[type]]   <- type_data[idx, ]
    remain_list[[type]] <- type_data[-idx, ]
  }
  
  list(
    testing_set        = dplyr::bind_rows(test_list),
    remaining_original = dplyr::bind_rows(remain_list)
  )
}

split1 <- split_testing_set(processed_dataframe_ext, test_prop = 0.30)

testing_set        <- split1$testing_set
remaining_original <- split1$remaining_original

# -------------------------------------------------------------------------#

# Split Dataset
split_data <- function(data, train_prop) {
  
  set.seed(seed_list[seed_counter])
  seed_counter <<- seed_counter + 1
  
  data <- data[sample(nrow(data)), ]
  
  train_rows <- round(nrow(data) * train_prop)
  
  train_data <- data[1:train_rows, ]
  test_data  <- data[(train_rows + 1):nrow(data), ]
  
  return(list(train = train_data, test = test_data))
}

prepare_dataset <- function(df) {
  
  training_set <- data.frame()
  validation_set <- data.frame()
  
  T <- 0.60
  V <- 0.10
  
  train_prop <- T / (T + V)
  
  for (label in sort(unique(df$tumor_label))) {
    
    label_data <- df %>% filter(tumor_label == label)
    
    for (type in sort(unique(label_data$tumor_type))) {
      
      type_data <- label_data %>% filter(tumor_type == type)
      
      n <- nrow(type_data)
      if (n < 3) {
        training_set <- rbind(training_set, type_data)
        next
      }
      
      set.seed(seed_list[seed_counter])
      seed_counter <<- seed_counter + 1
      
      train_index <- createDataPartition(
        type_data$tumor_label,
        p = train_prop,
        list = FALSE
      )
      
      train_data <- type_data[train_index, ]
      val_data   <- type_data[-train_index, ]
      
      training_set   <- rbind(training_set, train_data)
      validation_set <- rbind(validation_set, val_data)
    }
  }
  
  training_set$tumor_label   <- as.factor(training_set$tumor_label)
  validation_set$tumor_label <- as.factor(validation_set$tumor_label)
  
  X_train <- training_set %>% select(-tumor_label)
  y_train <- training_set$tumor_label
  
  X_val <- validation_set %>% select(-tumor_label)
  y_val <- validation_set$tumor_label
  
  return(list(
    X_train = X_train,
    y_train = y_train,
    X_val   = X_val,
    y_val   = y_val,
    training_set   = training_set,
    validation_set = validation_set
  ))
}

# -------------------------------------------------------------------------#

dataset_ext <- prepare_dataset(remaining_original)

training_set <- dataset_ext$training_set
validation_set <- dataset_ext$validation_set

tumor_type_levels <- sort(unique(remaining_original$tumor_type))

training_set$tumor_type <- factor(training_set$tumor_type, levels = tumor_type_levels)
validation_set$tumor_type <- factor(validation_set$tumor_type, levels = tumor_type_levels)

complete_dataset_ext <- rbind(training_set, validation_set, testing_set)

# -------------------------------------------------------------------------#

#extract ONE binary task
make_binary_task <- function(train, val, test, positive_type) {
  
  keep_types <- c("Normal", positive_type)
  
  train_bin <- train %>%
    filter(tumor_type %in% keep_types) %>%
    mutate(tumor_label = factor(
      ifelse(tumor_type == "Normal", "no_tumor", "tumor"),
      levels = c("no_tumor", "tumor")
    ))
  
  val_bin <- val %>%
    filter(tumor_type %in% keep_types) %>%
    mutate(tumor_label = factor(
      ifelse(tumor_type == "Normal", "no_tumor", "tumor"),
      levels = c("no_tumor", "tumor")
    ))
  
  test_bin <- test %>%
    filter(tumor_type %in% keep_types) %>%
    mutate(tumor_label = factor(
      ifelse(tumor_type == "Normal", "no_tumor", "tumor"),
      levels = c("no_tumor", "tumor")
    ))
  
  list(
    train = train_bin,
    validation = val_bin,
    test = test_bin
  )
}

task_brain <- make_binary_task(training_set, validation_set, testing_set, positive_type = "Brain.tumors")
train_brain <- task_brain$train
valid_brain <- task_brain$validation
test_brain  <- task_brain$test

task_sarcomas <- make_binary_task(training_set, validation_set, testing_set, positive_type = "Sarcomas")
train_sarcomas <- task_sarcomas$train
valid_sarcomas <- task_sarcomas$validation
test_sarcomas  <- task_sarcomas$test

bi_datasets <- list(
  brain = list(
    train = train_brain,
    valid = valid_brain,
    test  = test_brain
  ),
  sarcomas = list(
    train = train_sarcomas,
    valid = valid_sarcomas,
    test  = test_sarcomas
  )
)

# ----------------------------------IEEE ACCESS FORMAT---------------------------------------#

tumor_distribution_plots_ieee <- function(df, output_path = NULL) {
  
  tumor_summary <- df %>%
    mutate(tumor_label = ifelse(tumor_label == "tumor", "Tumor", "No Tumor")) %>%
    group_by(tumor_label) %>%
    summarise(Count = n(), .groups = "drop")
  
  tumor_sub_summary <- df %>%
    group_by(tumor_type) %>%
    summarise(Count = n(), .groups = "drop")
  
  main_plot <- ggplot(tumor_summary,
                      aes(x = tumor_label, y = Count, fill = tumor_label)) +
    geom_bar(stat = "identity") +
    geom_text(aes(label = Count),
              vjust = -0.4,
              size = 3,
              family = "Times New Roman") +
    labs(title = "Tumor vs No Tumor Distribution",
         x = "Class",
         y = "Number of Samples") +
    scale_fill_manual(values = c("Tumor" = "#D55E00",
                                 "No Tumor" = "#0072B2")) +
    theme_minimal(base_family = "Times New Roman", base_size = 9) +
    theme(plot.title = element_text(hjust = 0.5))
  
  sub_plot <- ggplot(tumor_sub_summary,
                     aes(x = reorder(tumor_type, -Count),
                         y = Count,
                         fill = tumor_type)) +
    geom_bar(stat = "identity") +
    geom_text(aes(label = Count),
              vjust = -0.4,
              size = 2.5,
              family = "Times New Roman") +
    labs(title = "Tumor Subtype Distribution",
         x = "Tumor Type",
         y = "Number of Samples") +
    theme_minimal(base_family = "Times New Roman", base_size = 9) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1),
          plot.title = element_text(hjust = 0.5),
          legend.position = "none")
  
  combined_plot <- arrangeGrob(main_plot, sub_plot, nrow = 1)
  
  if (!is.null(output_path)) {
    ggsave(filename = output_path,
           plot = combined_plot,
           dpi = 300,
           width = 8,
           height = 4,
           units = "in",
           bg = "white")
  } else {
    return(combined_plot)
  }
}

# Save plot
tumor_distribution_plots_ieee(complete_dataset_ext,
                              output_path = "D:/CPE407/THESIS/Result Bi/tumor_distribution_ext_ieee.png")

# -------------------------------------------------------------------------#

create_stacked_distribution_plot_ieee <- function(training_set,
                                                  validation_set,
                                                  testing_set,
                                                  output_path = NULL) {
  
  train_data <- training_set %>% mutate(set = "Train")
  val_data   <- validation_set %>% mutate(set = "Validation")
  test_data  <- testing_set %>% mutate(set = "Test")
  
  combined_df <- bind_rows(train_data, val_data, test_data) %>%
    mutate(set = factor(set, levels = c("Train", "Validation", "Test")))
  
  summary_df <- combined_df %>%
    group_by(set, tumor_type) %>%
    summarise(Count = n(), .groups = "drop")
  
  total_counts <- summary_df %>%
    group_by(set) %>%
    summarise(Total = sum(Count), .groups = "drop")
  
  pastel_colors <- c(
    "Brain.tumors" = "#AEC6CF",
    "Normal"       = "#B2D8B2",
    "Others"       = "#FFB6C1",
    "Sarcomas"     = "#FDFD96"
  )
  
  stacked_plot <- ggplot(summary_df,
                         aes(x = set, y = Count, fill = tumor_type)) +
    geom_bar(stat = "identity") +
    geom_text(aes(label = Count),
              position = position_stack(vjust = 0.5),
              size = 2.5,
              family = "Times New Roman") +
    geom_text(data = total_counts,
              aes(x = set, y = Total + 5, label = Total),
              inherit.aes = FALSE,
              size = 3,
              fontface = "bold",
              family = "Times New Roman") +
    labs(title = "Tumor Type Distribution: Binary Classification",
         x = "Dataset",
         y = "Number of Samples",
         fill = "Tumor Type") +
    scale_fill_manual(values = pastel_colors) +
    theme_minimal(base_family = "Times New Roman", base_size = 9) +
    theme(plot.title = element_text(hjust = 0.5))
  
  stacked_plot <- arrangeGrob(stacked_plot, nrow = 1)
  
  if (!is.null(output_path)) {
    ggsave(filename = output_path,
           plot = stacked_plot,
           dpi = 300,
           width = 6,
           height = 4,
           units = "in",
           bg = "white")
  } else {
    return(stacked_plot)
  }
}

create_stacked_distribution_plot_ieee(training_set, validation_set, testing_set,
                                      output_path = "D:/CPE407/THESIS/Result Bi/stacked_distribution_ext_ieee.png")
