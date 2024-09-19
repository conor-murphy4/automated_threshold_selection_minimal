#===============================================================================
# Code to produce the parameter stability plots shown in Figure 1 of the main paper. 
#===============================================================================
SEED = 1
library(evir)
source("src/parameter_stability.R")
source("src/helper_functions.R")

#Simulate sample 1 from case 4 of simulation study

case_4_sample_1 <- generate_case4_data(chosen_seed=SEED)

#Load Nidd data
data("nidd.thresh", package="evir")

#Define quantile levels and corresponding candidate threshold grids
Q_4 <- seq(0,0.95,by=0.05)
thresh_4 <- quantile(case_4_sample_1, Q_4, names=FALSE)

Q_Nidd <- seq(0,0.94,by=0.04) 
thresh_Nidd <- quantile(nidd.thresh,Q_Nidd, names=F)

#Create pdf file to save plots
pdf("output/figures/Figure_1_example_parameter_stability_plots.pdf", width=9.17, height=3.7)

#dev.new(width=9.17, height=3.7,noRStudioGD = TRUE) #Delete this line if happy with pdf
par(mfrow=c(1,2),bg='transparent')

#Generate parameter stability plots
shapestabboot(case_4_sample_1, thresholds = thresh_4, Q=Q_4, reverse=F, boot=TRUE,m.boot=200)
abline(v=1.0, col="green")

shapestabboot(nidd.thresh, thresholds = thresh_Nidd, Q=Q_Nidd, reverse=F, boot=TRUE,m.boot=200)

dev.off()