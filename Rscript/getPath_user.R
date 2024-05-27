# Define the directory path
user_directory <- "gs://csa_upload"

# List all files matching the pattern in the directory and its subdirectories
pattern <- "^gs://csa_upload/([^/]+)/\\1\\.bam$"
matching_path <- list.files(path = user_directory, recursive = TRUE, full.names = TRUE, pattern = pattern)

# Get the newest file based on modification time
user_dir <- matching_path[which.max(file.info(matching_path)$mtime)]
user_filenames <- sub(pattern, "\\1", user_dir)

# Extract the directory path
root_path <- dirname(user_dir)

# Construct the root path without the fixed pattern
root_path <- paste0(root_path, "/", user_filenames)

# Define the pattern for BAM file paths
bam_pattern <- paste0("^", user_filenames, "/", user_filenames, "\\.bam$")
bam_file_path <- paste0(root_path, "/", grep(bam_pattern, list.files(path = root_path, recursive = TRUE, full.names = TRUE, pattern = bam_pattern), value = TRUE))