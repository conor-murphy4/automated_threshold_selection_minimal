#===============================================================================
# Code to produce the QQ-plot and return level plot shown in Figure 2 of the 
# main paper. 
#===============================================================================

SEED = 11111
FIGURE_PATH = "output/figures/Figure_2_River_Nidd_analysis.pdf"

library(evir)
source("src/eqd.R")

# Load Nidd data
data("nidd.thresh", package = "evir")

# Define candidate threshold grid
thresholds <- quantile(nidd.thresh, probs = seq(from = 0, to = 0.93, by = 0.01))

# Select threshold using EQD method
set.seed(SEED) 
EQD_thr <- eqd(nidd.thresh, thresholds, k = 200)

# Generate results for QQ-plot -------------------------------------------------

u_hat <- EQD_thr$thresh 
excess <- nidd.thresh[nidd.thresh > u_hat] - u_hat 
n_u <- length(excess) 
probs <- c(1:n_u) / (n_u + 1) 

# Calculate sample quantiles 
q_sample <- quantile(excess, probs = probs, names = FALSE)

# Estimate model quantiles
model_fit <- optim(
  fn = GPD_LL,
  par = c(mean(excess), 0.1),
  z = excess,
  control = list(fnscale = -1))

q_model <- qgpd(probs, shape = EQD_thr$par[2], scale = EQD_thr$par[1])

# Estimate 95% tolerance bounds for model quantiles
num_boot <- 200 
boot_q_model_estimates <- matrix(NA, nrow = num_boot, ncol = length(probs)) 

set.seed(SEED)
for (i in 1:num_boot) {
  excess_boot <- rgpd(n_u, scale = EQD_thr$par[1], shape = EQD_thr$par[2]) 
  boot_model_fit <- optim(
    fn = GPD_LL,
    par = c(mean(excess_boot), 0.1),
    z = excess_boot,
    control = list(fnscale = -1)) 
  
  boot_q_model_estimates[i,] <- qgpd(
    p = probs,
    shape = boot_model_fit$par[2],
    scale = boot_model_fit$par[1]) 
}

q_l <- apply(boot_q_model_estimates, 2 , quantile, probs = 0.025) 
q_u <- apply(boot_q_model_estimates, 2 , quantile, probs = 0.975) 

# Generate results for return level plot ---------------------------------------

# Define return periods
t <- c(1, 2, 5, 10, 25, 50, 100, 500, 1000) 

# Estimate corresponding return levels

point_estimates <- u_hat + (EQD_thr$par[1] / EQD_thr$par[2]) * (((t * n_u) / 35)^(EQD_thr$par[2]) - 1) 

boot_return_ests <- matrix(NA, nrow = num_boot, ncol = length(t))

# Obtain bootstrap estimates of return levels incorporating only uncertainty in parameter estimates
set.seed(SEED)
for (i in 1:num_boot) {
  excess_boot <- rgpd(n = n_u, scale = EQD_thr$par[1], shape = EQD_thr$par[2]) 
  
  boot_model_fit <- optim(
    fn = GPD_LL,
    par = c(mean(excess_boot), 0.1),
    z = excess_boot,
    control = list(fnscale = -1)) 
  
  sig_over_xi <- boot_model_fit$par[1] / boot_model_fit$par[2]
  boot_return_ests[i,] <- u_hat + (sig_over_xi)*(((t*n_u)/35)^(boot_model_fit$par[2]) - 1) 
}

n <- length(nidd.thresh)
boot_return_ests_thr_uncertainty <- matrix(NA, nrow = num_boot^2, ncol = length(t))
boot_thr <- numeric(num_boot)

# Obtain bootstrap estimates of return levels incorporating uncertainty in parameter estimates and threshold selection

# NOTE: This section of code will take approximately 2 hours to run!
set.seed(SEED)
for (i in 1:num_boot) {
  cat(paste("Bootstrapping iteration: ", i, "of", num_boot,  "\n"))
  
  data_boot <- sample(nidd.thresh, n, replace = TRUE) 
  thresholds_boot <- quantile(data_boot, seq(from = 0, to = 0.93, by = 0.01)) 
  EQD_thr_boot <- eqd(data_boot, thresh = thresholds_boot, k = 200) 
  
  boot_thr[i] <- EQD_thr_boot$thresh 
  n_excess_boot <- length(data_boot[data_boot > EQD_thr_boot$thresh])  
  for (jj in 1:num_boot) {
    excess_boot <- rgpd(
      n = n_excess_boot,
      scale = EQD_thr_boot$par[1],
      shape = EQD_thr_boot$par[2])
    boot_model_fit <- optim(
      fn = GPD_LL,
      par = c(mean(excess_boot), 0.1),
      z = excess_boot,
      control = list(fnscale = -1))
    
    boot_return_est <- boot_thr[i] + 
      (boot_model_fit$par[1]/boot_model_fit$par[2])*(((t*n_excess_boot)/35)^(boot_model_fit$par[2]) - 1) 
    
    storage_row <- num_boot * (i - 1) + jj
    boot_return_ests_thr_uncertainty[storage_row, ] <- boot_return_est 
  }
}

# 95% confidence intervals incorporating parameter uncertainty
return_l <- apply(boot_return_ests, 2, quantile, 0.025) 
return_u <- apply(boot_return_ests, 2, quantile, 0.975) 

# 95% confidence intervals incorporating threshold and parameter uncertainty
return_thr_l <- apply(boot_return_ests_thr_uncertainty, 2, quantile, 0.025) 
return_thr_u <- apply(boot_return_ests_thr_uncertainty, 2, quantile, 0.975) 

# Create plots and save to pdf -------------------------------------------------
pdf(FIGURE_PATH, width = 9.17, height = 5)
par(mfrow = c(1,2))

# Quantile-Quantile Plot ------------------------------
plot(
  x = q_sample,
  y = q_model,
  xlab = "Sample Quantiles",
  ylab = "Model Quantiles",
  pch = 19,
  asp = 1,
  cex.lab = 1.1) 
polygon(
  x = c( q_l, sort(q_u, decreasing = TRUE)),
  y =  c(q_model, sort(q_model, decreasing = TRUE)),
  col = rgb(0, 0, 1, 0.2),
  border = NA) 
abline(a = 0, b = 1) 

# Return Level Plot -----------------------------------
plot(
  point_estimates ~ t,
  xlab = "Return Period (Years)",
  ylab = expression(Return~Level~(m^3/s)),
  ylim = c(100, 2500),
  log = 'x',
  type = 'l',
  lwd = 2,
  cex.lab = 1.1)
polygon(
  x = c( t, sort(t, decreasing = TRUE)),
  y = c(return_l,  sort(return_u, decreasing = TRUE)),
  col = rgb(1, 0, 0, 0.4),
  border = NA) 
polygon(
  x = c(t, sort(t, decreasing = TRUE)),
  y = c(return_thr_l,  sort(return_thr_u, decreasing = TRUE)),
  col = rgb(1, 0, 0, 0.2),
  border = NA) 

dev.off()