#===============================================================================
# Code to produce the estimates shown in Table 7 of the main paper. 
#===============================================================================

SEED = 11111
OUTPUT_PATH = "output/tables/Table_7_River_Nidd_dataset_selected_thresholds.csv"

library(evir)
library(threshr)
library(ismev)
library(mgcv)
library(nlme)
source("src/eqd.R")
source("src/JointMLEFunctions.r")

# Table 7:  --------------------------------------------------------------------

# Load Nidd data
data("nidd.thresh",package = "evir")

# Define candidate threshold grids
thresholds_list <- list(
  quantile(nidd.thresh, seq(from = 0, to = 0.93, by = 0.01)),
  quantile(nidd.thresh, seq(from = 0, to = 0.90, by = 0.01)),
  quantile(nidd.thresh, seq(from = 0, to = 0.80, by = 0.01)), 
  quantile(nidd.thresh, seq(from = 0, to = 0.80, by = 0.20)),
  quantile(nidd.thresh, seq(from = 0, to = 0.90, by = 0.30)),
  quantile(nidd.thresh, seq(from = 0, to = 0.75, by = 0.25)),
  quantile(nidd.thresh, c(0, 0.10, 0.40, 0.70)))

# Select threshold using each method-grid combination --------------------------

EQD_thr <- wads_thr <- north_thr <- numeric(length = length(thresholds_list))

for (i in seq_along(thresholds_list)) {
  
  cat(paste0("Starting threshold selection with candidate set ", i, " of 7.\n"))
  thresholds <- thresholds_list[[i]]
  
  cat("\t 1/3 selecting threshold using EQD method \n")
  set.seed(SEED) 
  EQD_thr[i] <- eqd(nidd.thresh, thresholds, k = 200)$thresh
  
  cat("\t 2/3 selecting threshold using Wadsworth method \n")
  set.seed(SEED)
  wads_thr[i] <- NHPP.diag(
    x = nidd.thresh,
    u = thresholds,
    plot.out = FALSE,
    UseQuantiles = FALSE)$thresh
  
  cat("\t 3/3 selecting threshold using Northrop method \n")
  set.seed(SEED)
  north_thr[i] <- summary(ithresh(nidd.thresh, u_vec = thresholds))[3]
}

table_7 <- data.frame(EQD = EQD_thr, Wadsworth = wads_thr, Northrop = north_thr)
print(table_7)

write.csv(table_7, OUTPUT_PATH)
