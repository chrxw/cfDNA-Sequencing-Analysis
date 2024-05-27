read_bamfile <- function(bamPath, binsize=1000, blacklist_files=NULL ,
                         genome="hg19" ,target_bedfile=NULL,
                         min_mapq=20, apply_blacklist= FALSE,
                         isMinusStrand = FALSE) {
  
  if_ucsc_chrformat <- function(bamPath) {
    all_chrs <- Rsamtools::idxstatsBam(bamPath)$seqnames
    return(any(all_chrs %in% c("chr1")))
  }
  
  GRCh2UCSCGRanges <- function (which) {
    GenomeInfoDb::seqlevels(which)<-
      sub('chrM',
          'M',GenomeInfoDb::seqlevels(which))
    GenomeInfoDb::seqlevels(which)<-
      gsub('^(.*)$','chr\\1',GenomeInfoDb::seqlevels(which))
    return(which)
  }
  
  UCSC2GRChSampleBam <- function (sample.bam) {
    names(sample.bam) <- gsub(
      "^chr","", names(sample.bam)
    )
    return(sample.bam)
  }
  
  if (!file.exists(bamPath)) {
    stop("The bamfile doesn't exist. Please check if the path to bamfile is valid.")
  }
  
  if (!is.null(target_bedfile)) {
    if (!file.exists(target_bedfile)) {
      stop("The given target bedfile doesn't exist.")
    }
  }
  
  if (!is.null(target_bedfile)) {
    if (!file.exists(target_bedfile)) {
      stop("The given target bedfile doesn't exist.")
    }
  }
  
  which <- util.get_sliding_windows(binsize = binsize, genome = genome)
  
  if (if_ucsc_chrformat(bamPath)) {
    which <- GRCh2UCSCGRanges(which)
  }
  
  flag <- Rsamtools::scanBamFlag(isPaired = TRUE,
                                 isUnmappedQuery = FALSE,
                                 isDuplicate = FALSE,
                                 isMinusStrand = isMinusStrand,
                                 hasUnmappedMate = FALSE,
                                 isSecondaryAlignment = FALSE,
                                 isMateMinusStrand = !isMinusStrand)
  
  param <- Rsamtools::ScanBamParam(what = c( "rname", "pos",
                                             "isize", "qwidth",
                                             "seq","strand"),
                                   flag = flag,
                                   which = which,
                                   mapqFilter = min_mapq)
  
  bam <- Rsamtools::scanBam(file = bamPath,
                            index = bamPath,
                            param = param)
  
  if (apply_blacklist) {
    message("Filtering-out read on the blacklist regions")
    bam <- filter_read_on_blacklist(bam, blacklist_files , genome = genome)
  }
  
  if (!is.null(target_bedfile)) {
    message("Extracting on-target fragments")
    bam <- extract_read_ontarget(bam, target_bedfile)
  }
  
  class(bam) <- "SampleBam"
  
  if (if_ucsc_chrformat(bamPath)) {
    bam <- UCSC2GRChSampleBam(bam)
  }
  
  return(bam)
}
