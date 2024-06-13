## Extract - the most frequency of end motif
# Load Biostrings package 
library(Biostrings)

# Getting sequence
plus.sequence_list = lapply(sample.bam.plusStrand, function(bin.list){
  bin.list[["seq"]]
})

minus.sequence_list = lapply(sample.bam.minusStrand, function(bin.list){
  bin.list[["seq"]]
})

# -------------------------------------------------------------------------#

# Convert minus read sequence to reverse complement sequence
minus.sequence_list = lapply(minus.sequence_list, Biostrings::reverseComplement)

#4-mer of forward strand
motif_4mers_plus_list_1  = lapply(plus.sequence_list, function(bin.sequences){
  Biostrings::subseq(bin.sequences, start = 1, end = 4)
})

motif_4mers_plus_list_2  = lapply(plus.sequence_list, function(bin.sequences){
  Biostrings::subseq(bin.sequences, start = bin.sequences@ranges@width - 3, end = bin.sequences@ranges@width)
})

#4-mer of reverse strand
motif_4mers_minus_list_1  = lapply(minus.sequence_list, function(bin.sequences){
  Biostrings::subseq(bin.sequences, start = 1, end = 4)
})

motif_4mers_minus_list_2  = lapply(minus.sequence_list, function(bin.sequences){
  Biostrings::subseq(bin.sequences, start = bin.sequences@ranges@width - 3, end = bin.sequences@ranges@width)
})

# -------------------------------------------------------------------------#

### Function to create a combination of DNA sequence give a pattern of N seq. 
### The function will replace 'N' with permutation of all DNA bases 
create.motif.seqs = function(dna.seq = 'NNNN') { 
  library(data.table)
  # split into components
  l = tstrsplit(dna.seq, '', fixed = TRUE)
  # replace N with all possibilities
  all_bases = c('A', 'T', 'C', 'G')
  l = lapply(l, function(x) if (x == 'N') all_bases else x)
  # use CJ and reduce to strings:
  return(Reduce(paste0, do.call(CJ, l)))
}

# Get all DNA motif sequence of length 4
motif_seqs_pattern = create.motif.seqs("NNNN")

# -------------------------------------------------------------------------#

# Count #N of each motif in plus strand
motif_count.plus_1 = t(sapply(motif_4mers_plus_list_1, function(motif.seq){
  motif.seqs = as.character(motif.seq)[which(as.character(motif.seq) %in% motif_seqs_pattern)]
  motif.count = summary(factor(motif.seqs, levels = motif_seqs_pattern),
                        maxsum = length(motif_seqs_pattern))
}))

motif_count.plus_2 = t(sapply(motif_4mers_plus_list_2, function(motif.seq){
  motif.seqs = as.character(motif.seq)[which(as.character(motif.seq) %in% motif_seqs_pattern)]
  motif.count = summary(factor(motif.seqs, levels = motif_seqs_pattern),
                        maxsum = length(motif_seqs_pattern))
}))

### Count #N of each motif in minus strand
motif_count.minus_1 = t(sapply(motif_4mers_minus_list_1, function(motif.seq){
  motif.seqs = as.character(motif.seq)[which(as.character(motif.seq) %in% motif_seqs_pattern)]
  motif.count = summary(factor(motif.seqs, levels = motif_seqs_pattern),
                        maxsum = length(motif_seqs_pattern))
}))

motif_count.minus_2 = t(sapply(motif_4mers_minus_list_2, function(motif.seq){
  motif.seqs = as.character(motif.seq)[which(as.character(motif.seq) %in% motif_seqs_pattern)]
  motif.count = summary(factor(motif.seqs, levels = motif_seqs_pattern),
                        maxsum = length(motif_seqs_pattern))
}))

### Sum number of motif in a bam sample
motif_total.counts_fwd_1 = colSums(motif_count.plus_1)
motif_total.counts_fwd_2 = colSums(motif_count.plus_2)
motif_total.counts_rev_1 = colSums(motif_count.minus_1)
motif_total.counts_rev_2 = colSums(motif_count.minus_2)

motif_total.counts_lead = colSums(motif_count.plus_1) + colSums(motif_count.minus_1)
motif_total.counts_last = colSums(motif_count.plus_2) + colSums(motif_count.minus_2)

# -------------------------------------------------------------------------#

### Calculate proportion of motif
# Define a function to calculate the frequency
# Name of the most frequent motif
most_frequent_name <- function(counts_vector) {
  return(names(counts_vector)[which.max(counts_vector)])}
# Count of the most frequent motif
most_frequent_count <- function(counts_vector) {
  return(counts_vector[which.max(counts_vector)])}

# Get the most frequent motif each end-motif side
most_frequent_motif_fwd_1 <- most_frequent_name(motif_total.counts_fwd_1)
most_frequent_motif_fwd_2 <- most_frequent_name(motif_total.counts_fwd_2)
most_frequent_motif_rev_1 <- most_frequent_name(motif_total.counts_rev_1)
most_frequent_motif_rev_2 <- most_frequent_name(motif_total.counts_rev_2)

# Get the most frequent motif overall
most_frequent_motif_lead <- most_frequent_name(motif_total.counts_lead)
most_frequent_motif_last <- most_frequent_name(motif_total.counts_last)

# -------------------------------------------------------------------------#

### Calculate proportion of motif
# Define a function to calculate the proportion
# Calculate of peak proportion
calculate_peak_proportion <- function(peak_counts, total_counts) {
  return(as.numeric(peak_counts / sum(total_counts)))}
# Calculate of pattern proportion
calculate_pattern_proportion <- function(unique_patterns, total_possible_patterns) {
  return(length(unique_patterns) / total_possible_patterns)}

# Generate all possible motifs with 4 characters (ATCG)
all_possible_motifs <- expand.grid(replicate(4, c("A", "T", "C", "G"), simplify = FALSE))
all_possible_motifs <- do.call(paste0, all_possible_motifs)
total_possible_patterns <- length(all_possible_motifs)

# Calculate proportions for peak motifs
proportion_fwd_1 <- calculate_peak_proportion(most_frequent_count(motif_total.counts_fwd_1), motif_total.counts_fwd_1)
proportion_fwd_2 <- calculate_peak_proportion(most_frequent_count(motif_total.counts_fwd_2), motif_total.counts_fwd_2)
proportion_rev_1 <- calculate_peak_proportion(most_frequent_count(motif_total.counts_rev_1), motif_total.counts_rev_1)
proportion_rev_2 <- calculate_peak_proportion(most_frequent_count(motif_total.counts_rev_2), motif_total.counts_rev_2)
proportion_lead <- calculate_peak_proportion(most_frequent_count(motif_total.counts_lead), motif_total.counts_lead)
proportion_last <- calculate_peak_proportion(most_frequent_count(motif_total.counts_last), motif_total.counts_last)

# Calculate proportions for unique motif patterns
unique_patterns_plus_1 <- unique(names(motif_total.counts_fwd_1))
unique_patterns_plus_2 <- unique(names(motif_total.counts_fwd_2))
unique_patterns_minus_1 <- unique(names(motif_total.counts_rev_1))
unique_patterns_minus_2 <- unique(names(motif_total.counts_rev_2))
unique_patterns_lead <- unique(names(motif_total.counts_lead))
unique_patterns_last <- unique(names(motif_total.counts_last))

pattern_proportion_fwd_1 <- calculate_pattern_proportion(unique_patterns_plus_1, total_possible_patterns)
pattern_proportion_fwd_2 <- calculate_pattern_proportion(unique_patterns_plus_2, total_possible_patterns)
pattern_proportion_rev_1 <- calculate_pattern_proportion(unique_patterns_minus_1, total_possible_patterns)
pattern_proportion_rev_2 <- calculate_pattern_proportion(unique_patterns_minus_2, total_possible_patterns)
pattern_proportion_lead <- calculate_pattern_proportion(unique_patterns_lead, total_possible_patterns)
pattern_proportion_last <- calculate_pattern_proportion(unique_patterns_last, total_possible_patterns)
