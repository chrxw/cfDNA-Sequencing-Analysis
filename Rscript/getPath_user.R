# Define the directory path
user_directory <- "gs://csa_upload"

# List all directories in the specified path
all_dirs <- list.dirs(path = user_directory, full.names = TRUE, recursive = FALSE)

# Get the newest file based on modification time
user_dir <- all_dirs[which.max(file.info(all_dirs)$mtime)]
user_filenames <- tools::file_path_sans_ext(basename(user_dir))

# Extract the directory path
root_path <- dirname(user_dir)

# Define the pattern for BAM file paths
bam_pattern <- "\\.bam$"
bam_files <- list.files(path = user_dir, recursive = TRUE, full.names = FALSE, pattern = bam_pattern)
bam_file_path <- file.path(root_path, user_filenames, bam_files[1])
bam_index_path <- paste0(bam_file_path, ".bai")