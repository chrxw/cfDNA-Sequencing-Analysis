## Get ichorCNA
# Define directory path
txt_user_directory <- "gs://csa_upload"

# Define the pattern for ichorCNA file paths
ichor_pattern <- paste0("^", user_filenames, "/ichorCNA/", user_filenames, "\\.params\\.txt$")
ichor_file_path <- paste0(root_path, "/", grep(ichor_pattern, list.files(path = root_path, recursive = TRUE, full.names = TRUE, pattern = ichor_pattern), value = TRUE))

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
