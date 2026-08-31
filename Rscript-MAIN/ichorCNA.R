## Get ichorCNA
# Define the pattern for ichorCNA file paths
ichor_pattern <- paste0(user_filenames, ".*\\.params\\.txt$")
ichor_files <- list.files(path = user_dir, recursive = TRUE, full.names = FALSE, pattern = ichor_pattern)
ichor_file_path <- file.path(root_path, user_filenames, ichor_files[1])

# -------------------------------------------------------------------------#

# Define a list to store tumor fractions
tumor_fraction <- list()

# Iterate over each file path in ichorPath
for (textpath in ichor_file_path) {
  # Open the file for reading
  lines <- readLines(textpath)
  
  # Check if there are at least two lines
  if (length(lines) >= 2) {
    # Extract the second line
    result_line <- lines[2]
    
    # Split the second line by tab ('\t')
    values <- strsplit(result_line, "\t")[[1]]
    
    # Check if there are enough values
    if (length(values) > 1) {
      # Extract the second value
      tumor_frac <- values[2]
      
      # Append the tumor fraction to the list
      tumor_fraction <- c(tumor_fraction, as.numeric(tumor_frac))
    }
  }
}
