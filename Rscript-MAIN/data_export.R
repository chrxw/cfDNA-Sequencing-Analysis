# Integrate Column
all_feature <- c(sample_names, isize_len, isize_label, most_frequent_motif_fwd_1, 
                 most_frequent_motif_fwd_2, most_frequent_motif_rev_1, most_frequent_motif_rev_2, 
                 most_frequent_motif_lead, most_frequent_motif_last, proportion_fwd_1, proportion_fwd_2, 
                 proportion_rev_1, proportion_rev_2, proportion_lead, proportion_last, 
                 pattern_proportion_fwd_1, pattern_proportion_fwd_2, pattern_proportion_rev_1, 
                 pattern_proportion_rev_2, pattern_proportion_lead, pattern_proportion_last, 
                 CES_score, sl_ratio, tumor_fraction[[sample_counter]], tumor_type[[sample_counter]], 
                 label_tumor[[sample_counter]])

# Assign column names
column_names <- c("sample_id", "isize_peak", "isize_label", "motif_peak_fwd_1", "motif_peak_fwd_2", 
                  "motif_peak_rev_1", "motif_peak_rev_2", "motif_peak_1", "motif_peak_2", "prop_fwd_1", 
                  "prop_fwd_2", "prop_rev_1", "prop_rev_2", "prop_1", "prop_2", "pattern_prop_fwd_1", 
                  "pattern_prop_fwd_2", "pattern_prop_rev_1", "pattern_prop_rev_2", "pattern_prop_1", 
                  "pattern_prop_2", "ces", "sl_ratio", "tumor_fraction", "tumor_type", "tumor_label")
names(all_feature) <- column_names

# Convert the list to a data frame
cfdna_df <- data.frame(all_feature)

# Export data to RDS file
saveRDS(cfdna_df, file = paste0("path/to/your/cfdna_", sample_counter, ".rds"))
