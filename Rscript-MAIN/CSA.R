## Setting
# Run R script
source("/path/to/your/utils.R")
source("/path/to/your/read_bamfile.R")
source("/path/to/your/getPath.R") # path # tumor_label
source("/path/to/your/read_text.R") # tumor_fraction
source("/path/to/your/read_xlsx.R") # tumor_type

# Receive value from CMD line
args <- commandArgs(trailingOnly = TRUE)
if (length(args) == 0) {
  stop("No path provided!")
}
path <- args[1]
counter <- args[2]
sample_counter <- as.numeric(counter)

# -------------------------------------------------------------------------#

## Execute cfdnakit
# Load Package
library(cfdnakit)

# Define lists to store sample names and read numbers
sample_names <- list()
sample_no <- list()
CES_score <- list()
sl_ratio <- list()

all_feature <- list()
  
# Get the basename of the path
basename_path <- basename(path)
  
## Append the basename to the sample_names list
sample_names <- c(sample_names, basename_path)
    
## Reading in a bamfile
sample.bam <- read_bamfile(path, apply_blacklist = FALSE)
sample.bam.plusStrand = read_bamfile(path, isMinusStrand = FALSE)
sample.bam.minusStrand = read_bamfile(path, isMinusStrand = TRUE)
sample.bam = na.omit(sample.bam)
message("Read bamfile:: SUCCESS")
    
## Plot a fragment-length distribution of two samples
control_RDS_file <-
  system.file("extdata","BH01_CHR15.SampleBam.rds",
              package = "cfdnakit")
    
### Load example SampleBam of Healthy cfDNA
control_bins <- readRDS(control_RDS_file)
    
comparing_list = list("Healthy.cfDNA"= control_bins, "Patient.cfDNA" = sample.bam )
    
## Derived and plot genome-wide short-fragment cfDNA
sample.bamProfile =
  get_fragment_profile(sample.bam, sample_id = "Patient.cfDNA")
    
## Derived and plot normalized short-fragment cfDNA
PoN_rdsfile =  system.file("extdata", "ex.PoN.rds", package = "cfdnakit")
    
## Loading example PoN data
PoN.profiles = readRDS(PoN_rdsfile)
    
sample_zscore = get_zscore_profile(sample.bamProfile, PoN.profiles)
sample_zscore_segment = segmentByPSCB(sample_zscore)
    
## Estimate circulating tumor DNA
CES.score <- calculate_CES_score(sample_zscore_segment)
CES_score <- c(CES_score, CES.score)
CES_score
    
## S/L ratio
sl.ratio <- sample.bamProfile$sample_profile[["S.L.Ratio"]]
sl_ratio <- c(sl_ratio, sl.ratio)
sl_ratio
  
source("/path/to/your/cfdna_feature_1.R")
source("/path/to/your/cfdna_feature_2_motif.R")

source("/path/to/your/data_export.R")
