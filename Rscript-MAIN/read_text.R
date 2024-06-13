## Get ichorCNA
# Define directory path
txt_directory <- "/omics/odcf/analysis/OE0290_projects/pediatric_tumor/whole_genome_sequencing_CRAsnakemake/HDS_project/dataML"

# List all files in the directory and its subdirectories
ichorcna <- list.files(path = txt_directory, recursive = TRUE, full.names = TRUE)

# Filter files to include only those matching the pattern
ichorPath <- ichorcna[grep(".+/OE0290-PED_[0-9]+LB-[0-9]+/plasma-[0-9]+-[0-9]+/ichorCNA/OE0290-PED_[0-9]+LB-[0-9]+_plasma-[0-9]+-[0-9]+.params.txt", ichorcna)]

# Show the list of paths
ichorPath

# -------------------------------------------------------------------------#

# Define a list to store tumor fractions
tumor_fraction <- list()

# Iterate over each file path in ichorPath
for (textpath in ichorPath) {
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
