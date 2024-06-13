## Original Sample
# Define the main directory path
original_directory <- "/omics/odcf/analysis/OE0290_projects/pediatric_tumor/whole_genome_sequencing_CRAsnakemake/HDS_project/dataML"

# List all files in the main directory and its subdirectories
og_all_files <- list.files(path = original_directory, recursive = TRUE, full.names = TRUE)

# Filter files to include only those matching the pattern "*_plasma*_MD.bam"
sample_dir <- og_all_files[grep("_plasma.*_MD\\.bam$", og_all_files)]
sample_dir <- sample_dir[!grepl("_full", sample_dir)]

# Show the list of paths
sample_dir

## Path list for control & patient
# Filter paths containing "OE0290-PED_0LB"
ctr_part <- grepl("OE0290-PED_0LB", sample_dir)
control_dir <- sample_dir[ctr_part]
patient_dir <- sample_dir[!ctr_part]

# Show the list of paths
control_dir
patient_dir

## Merge base (control + sample) list
# Merge the lists
base_dir <- c(control_dir, patient_dir)

# Show the list of paths
base_dir

# -------------------------------------------------------------------------#

## Resample Sample
# Define the main directory path
resample_directory <- "/omics/odcf/analysis/OE0290_projects/pediatric_tumor/whole_genome_sequencing_CRAsnakemake/HDS_project/ControlResampling"

# List all files in the main directory and its subdirectories
re_all_files <- list.files(path = resample_directory, recursive = TRUE, full.names = TRUE)

# Filter files to include only those matching the pattern "*_plasma*_MD.bam"
library(gtools)

resample_dir <- re_all_files[grep(".+/control_[0-9]+/control_hg38_[0-9]+_MD\\.bam$", re_all_files)]
resample_dir <- mixedsort(resample_dir)

# Show the list of paths
resample_dir

# -------------------------------------------------------------------------#

## Merge all list
# Merge the lists
all_dir <- c(control_dir, resample_dir, patient_dir)

# Show the list of paths
all_dir

# -------------------------------------------------------------------------#

# Function to label paths
labels <- function(path) {
  if (path %in% c(control_dir, resample_dir)) {
    return("no_tumor")
  } else {
    return("tumor")
  }
}

# Apply the function to all paths in all_dir
label_tumor <- lapply(all_dir, labels)

# Display the labels
label_tumor

# -------------------------------------------------------------------------#

file_conn <- file("/omics/odcf/analysis/OE0290_projects/pediatric_tumor/whole_genome_sequencing_CRAsnakemake/HDS_project/all_dir.txt", "w")

# Write each element of the list to the file
for (item in all_dir){
  cat(item, "\n", file = file_conn)}

# Close the file connection
close(file_conn)

# -------------------------------------------------------------------------#

# Create a data frame with one column containing all_dir
all_dir_df <- data.frame(path = all_dir)

# Define the file path for the text file
print_file_path <- "/omics/odcf/analysis/OE0290_projects/pediatric_tumor/whole_genome_sequencing_CRAsnakemake/HDS_project/MachineLearning/Path/all_dir.txt"

# Export the paths to a text file
writeLines(all_dir, con = print_file_path)
