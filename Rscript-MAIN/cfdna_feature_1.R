## Peak isize

isize_len <- list()
isize_label <- list()

# Use function from cfdnakit
isize_frequency <- plot_fragment_dist(list("cfdna.sample" = sample.bam))

# Extract peak_length values
isize_lengths <- isize_frequency$data$peak_length

# Calculate frequency of each unique peak length
peak_length_freq <- table(isize_lengths)

# Find the peak length with the highest frequency
peak_length <- as.numeric(names(which.max(peak_length_freq)))

# Check if peak_length is less than 150 bases
if (peak_length <= 150) {
  # If less than 150 bases, append "short" to the list
  isize_label <- c(isize_label, "short")
} else {
  # If 150 bases or more, append "long" to the list
  isize_label <- c(isize_label, "long")
}

# Add peak_length to the list
isize_len <- c(isize_len, peak_length)
