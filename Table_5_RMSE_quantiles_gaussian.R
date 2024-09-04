#Parameters controlling simulation and output

GENERATE_DATA <- FALSE #Change this parameter to TRUE to generate new threshold estimates. If GENERATE_DATA is set to FALSE, the code will use the estimates saved in the output folder.

FULL_TABLE <- FALSE #Change this parameter to TRUE to include the estimates in Table 5 which relate to the sample size of n=20000. 
# NOTE: if GENERATE_DATA and FULL_TABLE are both set to TRUE, the code will generate new estimates for n=2000 and n=20000 which will take some time to run.


library(Metrics)

#Threshold choices
if(GENERATE_DATA){
  source("src/eqd.R")
  source("src/JointMLEFunctions.R")
  library(threshr)

  #Gaussian case
  sample_size <- 2000
  num_samples <- 500
  probs=seq(0.5, 0.95, by=0.05)
  mythresh <- wadsthresh <- norththresh <- numeric(num_samples)
  myquantile <- wadsquantile <- northquantile <- numeric(num_samples)
  myscale <- wadsscale <- northscale <- numeric(num_samples)
  myshape <- wadsshape <- northshape <- numeric(num_samples)
  mylen <- wadslen <- northlen <- numeric(num_samples)
  data_matrix <- matrix(NA, nrow=sample_size, ncol=num_samples)
  for(ii in 1:num_samples){
    print(ii)
    set.seed(ii)
    data <- rnorm(sample_size)
    data_matrix[,ii] <- data
    thresh <- quantile(data, probs, names=F)
    
    #EQD method
    myres <- eqd(data, thresh=thresh)
    mythresh[ii] <- myres$thresh
    myquantile[ii] <- probs[thresh==mythresh[ii]]
    myscale[ii] <- myres$par[1]
    myshape[ii] <- myres$par[2]
    mylen[ii] <- myres$num_excess
    
    #Wadsworth 2016 method
    wadsthresh[ii] <- NHPP.diag(data, u=thresh, plot.out = FALSE, UseQuantiles = FALSE)$thresh[[1]]
    if(!is.na(wadsthresh[ii])){
      fit.data_w <- data[data>wadsthresh[ii]] - wadsthresh[ii]
      optwads <- optim(GPD_LL, z=fit.data_w, par=c(mean(fit.data_w), 0.1), control=list(fnscale=-1))
      wadsscale[ii] <- optwads$par[1]
      wadsshape[ii] <- optwads$par[2]
      wadslen[ii] <- length(fit.data_w)
      wadsquantile[ii] <- probs[thresh==wadsthresh[ii]]
    }
    else{
      wadsscale[ii] <- NA
      wadsshape[ii] <- NA
      wadslen[ii] <- NA
      wadsquantile[ii] <- NA
    }
    
    #Northrop 2017 method
    norththresh[ii] <- summary(ithresh(data, u_vec = thresh))[3]
    northquantile[ii] <- probs[thresh==norththresh[ii]]
    fit.data_n <- data[data>norththresh[ii]] - norththresh[ii]
    optnorth <- optim(GPD_LL, z=fit.data_n, par=c(mean(fit.data_n), 0.1), control=list(fnscale=-1))
    northscale[ii] <- optnorth$par[1]
    northshape[ii] <- optnorth$par[2]
    northlen[ii] <- length(fit.data_n)
  }
  
  
  eqdthr_gauss <- data.frame(thr=mythresh,quantile=myquantile, scale=myscale, shape=myshape, len=mylen)
  wadsthr_gauss <- data.frame(thr=wadsthresh,quantile=wadsquantile, scale=wadsscale, shape=wadsshape, len=wadslen)
  norththr_gauss <- data.frame(thr=norththresh, quantile=northquantile, scale=northscale, shape=northshape, len=northlen)
  
  write.csv(data_matrix, "data/Gaussian.csv")
  write.csv(eqdthr_gauss, "output/threshold_selection/eqd_gauss.csv")
  write.csv(wadsthr_gauss, "output/threshold_selection/wads_gauss.csv")
  write.csv(norththr_gauss, "output/threshold_selection/north_gauss.csv")
  
  if(FULL_TABLE){
    sample_size <- 20000
    num_samples <- 500
    probs=seq(0.5, 0.95, by=0.005)
    mythresh <- wadsthresh <- norththresh <- numeric(num_samples)
    myquantile <- wadsquantile <- northquantile <- numeric(num_samples)
    myscale <- wadsscale <- northscale <- numeric(num_samples)
    myshape <- wadsshape <- northshape <- numeric(num_samples)
    mylen <- wadslen <- northlen <- numeric(num_samples)
    data_matrix <- matrix(NA, nrow=sample_size, ncol=num_samples)
    for(ii in 1:num_samples){
      print(ii)
      set.seed(ii)
      data <- rnorm(sample_size)
      data_matrix[,ii] <- data
      thresh <- quantile(data, probs, names=F)
      
      #EQD method
      myres <- eqd(data, thresh=thresh)
      mythresh[ii] <- myres$thresh
      myquantile[ii] <- probs[thresh==mythresh[ii]]
      myscale[ii] <- myres$par[1]
      myshape[ii] <- myres$par[2]
      mylen[ii] <- myres$num_excess
      
      #Wadsworth 2016 method
      wadsthresh[ii] <- NHPP.diag(data, u=thresh, plot.out = FALSE, UseQuantiles = FALSE)$thresh[[1]]
      if(!is.na(wadsthresh[ii])){
        fit.data_w <- data[data>wadsthresh[ii]] - wadsthresh[ii]
        optwads <- optim(GPD_LL, z=fit.data_w, par=c(mean(fit.data_w), 0.1), control=list(fnscale=-1))
        wadsscale[ii] <- optwads$par[1]
        wadsshape[ii] <- optwads$par[2]
        wadslen[ii] <- length(fit.data_w)
        wadsquantile[ii] <- probs[thresh==wadsthresh[ii]]
      }
      else{
        wadsscale[ii] <- NA
        wadsshape[ii] <- NA
        wadslen[ii] <- NA
        wadsquantile[ii] <- NA
      }
      
      #Northrop 2017 method
      norththresh[ii] <- summary(ithresh(data, u_vec = thresh))[3]
      northquantile[ii] <- probs[thresh==norththresh[ii]]
      fit.data_n <- data[data>norththresh[ii]] - norththresh[ii]
      optnorth <- optim(GPD_LL, z=fit.data_n, par=c(mean(fit.data_n), 0.1), control=list(fnscale=-1))
      northscale[ii] <- optnorth$par[1]
      northshape[ii] <- optnorth$par[2]
      northlen[ii] <- length(fit.data_n)
    }
    
    
    eqdthr_gauss <- data.frame(thr=mythresh,quantile=myquantile, scale=myscale, shape=myshape, len=mylen)
    wadsthr_gauss <- data.frame(thr=wadsthresh,quantile=wadsquantile, scale=wadsscale, shape=wadsshape, len=wadslen)
    norththr_gauss <- data.frame(thr=norththresh, quantile=northquantile, scale=northscale, shape=northshape, len=northlen)
    
    write.csv(data_matrix, "data/Gaussian_large.csv")
    write.csv(eqdthr_gauss, "output/threshold_selection/eqd_gauss_large.csv")
    write.csv(wadsthr_gauss, "output/threshold_selection/wads_gauss_large.csv")
    write.csv(norththr_gauss, "output/threshold_selection/north_gauss_large.csv")
  }
}

if(!GENERATE_DATA){
eqd_gauss <- read.csv("output/threshold_selection/eqd_gauss_24072024.csv", row.names = 1, header = T)
wads_gauss <- read.csv("output/threshold_selection/wads_gauss_24072024.csv", row.names = 1, header = T)
north_gauss <- read.csv("output/threshold_selection/north_gauss_24072024.csv", row.names = 1, header = T)

  if(FULL_TABLE){
    eqd_gauss_large <- read.csv("output/threshold_selection/eqd_gauss_large_24072024.csv", row.names = 1, header = T)
    wads_gauss_large <- read.csv("output/threshold_selection/wads_gauss_large_24072024.csv", row.names = 1, header = T)
    north_gauss_large <- read.csv("output/threshold_selection/north_gauss_large_24072024.csv", row.names = 1, header = T)
  }
}

if(FULL_TABLE){
  eqd_list <- list(eqd_gauss, eqd_gauss_large)
  wads_list <- list(wads_gauss, wads_gauss_large)
  north_list <- list(north_gauss, north_gauss_large)
}
if(!FULL_TABLE){
  eqd_list <- list(eqd_gauss)
  wads_list <- list(wads_gauss)
  north_list <- list(north_gauss)
}

#------------------Estimated quantiles------------------
estimated_quantile <- function(df,p,n){
  lu <- df$len/n
  est_quants <- df$thr + (df$scale/df$shape)*((p/lu)^(-df$shape)-1)
  return(est_quants)
}

#---------RMSE of estimated quantiles for Gaussian case--------------------


sample_sizes <- c(2000,20000)
if(FULL_TABLE){
  sample_sizes <- c(2000,20000)
}
if(!FULL_TABLE){
  sample_sizes <- c(2000)
}
num_cases <- length(sample_sizes)
RMSE_gauss <- vector('list',num_cases)
for(case in 1:num_cases){
  n <- sample_sizes[case]
  p_seq <- c(1/n,1/(10*n), 1/(100*n))
  eqd_df <- eqd_list[[case]]
  wads_df <- wads_list[[case]]
  north_df <- north_list[[case]]
  
  eqd_est_quants <- sapply(p_seq, estimated_quantile, df=eqd_df, n=n)
  wads_est_quants <- sapply(p_seq, estimated_quantile, df=wads_df[!is.na(wads_df$thr),], n=n)
  north_est_quants <- sapply(p_seq, estimated_quantile, df=north_df, n=n)
  
  true_quants <- qnorm(1-p_seq)
  
  eqd_rmse_quants <- wads_rmse_quants <- north_rmse_quants <- numeric(3)
  for(i in 1:3){
    eqd_rmse_quants[i] <- rmse(eqd_est_quants[,i], true_quants[i])
    wads_rmse_quants[i] <- rmse(wads_est_quants[,i], true_quants[i])
    north_rmse_quants[i] <- rmse(north_est_quants[,i], true_quants[i])
  }
  
  RMSE_gauss[[case]] <- data.frame(j=c(0,1,2), EQD=eqd_rmse_quants, Wadsworth=wads_rmse_quants, Northrop=north_rmse_quants)
}

print(RMSE_gauss)

saveRDS(RMSE_gauss, "output/tables/Table_5_rmse_quantile_estimates_gaussian.rds")
