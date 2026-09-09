# Run R script
source("cfDNA-Sequencing-Analysis/Rscript-MAIN/utils.R")
source("cfDNA-Sequencing-Analysis/Rscript-MAIN/read_bamfile.R")
source("cfDNA-Sequencing-Analysis/Rscript-MAIN/getPath_BAM.R") # path # tumor_label
source("cfDNA-Sequencing-Analysis/Rscript-MAIN/ichorCNA.R") # tumor_fraction

# -------------------------------------------------------------------------#

## Execute cfdnakit
# Load Package
library(cfdnakit)

sample_counter <- 0
sample_names <- list()
CES_score <- list()
sl_ratio <- list()

all_feature <- list()

# Iterate over each path in bam_file_path
for (path in bam_file_path) {
  
  sample_counter <- sample_counter + 1
  sample_names <- user_filenames
  
  ## Reading in a bamfile
  message("Read bamfile:: PROCESS")
  sample.bam <- read_bamfile(path, apply_blacklist = FALSE)
  sample.bam.plusStrand = read_bamfile(path, isMinusStrand = FALSE)
  sample.bam.minusStrand = read_bamfile(path, isMinusStrand = TRUE)
  sample.bam = na.omit(sample.bam)
  message("Read bamfile:: SUCCESS")
  
  control_RDS_file <-
    system.file("extdata","BH01_CHR15.SampleBam.rds",
                package = "cfdnakit")
  
  ### Load example SampleBam of Healthy cfDNA
  control_bins <- readRDS(control_RDS_file)
  
  comparing_list = list("Healthy.cfDNA"= control_bins,
                        "Patient.cfDNA"= sample.bam )
  
  ## Derived and plot genome-wide short-fragment cfDNA
  # message("Ploting S/L ratio")
  sample.bamProfile =
    get_fragment_profile(sample.bam,
                         sample_id = "Patient.cfDNA")
  
  ## Derived and plot normalized short-fragment cfDNA
  PoN_rdsfile =  system.file(
    "extdata",
    "ex.PoN.rds",
    package = "cfdnakit")
  
  ## Loading example PoN data
  PoN.profiles = readRDS(PoN_rdsfile)
  
  sample_zscore =
    get_zscore_profile(sample.bamProfile,
                       PoN.profiles)
  sample_zscore_segment = segmentByPSCB(sample_zscore)
  
  ## Estimate circulating tumor DNA
  CES.score <- calculate_CES_score(sample_zscore_segment)
  CES_score <- c(CES_score, CES.score)
  CES_score
  
  ## S/L ratio
  sl.ratio <- sample.bamProfile$sample_profile[["S.L.Ratio"]]
  sl_ratio <- c(sl_ratio, sl.ratio)
  sl_ratio
  
}

source("cfDNA-Sequencing-Analysis/Rscript-MAIN/cfdna_feature_1.R")
source("cfDNA-Sequencing-Analysis/Rscript-MAIN/cfdna_feature_2_motif.R")

source("cfDNA-Sequencing-Analysis/Rscript-MAIN/BAM_RDS.R")
