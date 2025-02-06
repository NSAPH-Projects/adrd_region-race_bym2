## load packages ----
library(tidyverse)
library(magrittr)
library(rstan)


# incorporating Medicaid eligibility into expected counts?
dual <- TRUE
#dual <- FALSE


# in command line, run something like:
# sbatch analysis/04-run_stage1.sbatch adrd m2
# (with appropriate outcome and model)

# Parse command-line arguments (specifies which outcome and model to run)
# should be m1, m2, or m3
args <- commandArgs(trailingOnly = TRUE)
outcome_to_run <- args[1]
model_to_run <- args[2]

# or run this if not using sbatch
#outcome_to_run <- "hosp"     # or adrd
#model_to_run = "m2"          # or m2, m3

# outcome_to_run is adrd if using dual (not adrd-dual)

# print model this is running
paste0(outcome_to_run)
paste0(model_to_run)
paste0("dual = ", dual)

if(dual){
  path_mod <- paste0("results/models/dual/stage1/", outcome_to_run, "/", model_to_run, "/")
} else {
  path_mod <- paste0("results/models/stage1/", outcome_to_run, "/", model_to_run, "/")
}


# get correct stan file for this model
if (model_to_run == "m1") {
  stan_file <- "stan_programs/stage1_no_covar.stan"
} else if (model_to_run == "m2") {
  stan_file <- "stan_programs/stage1_covar.stan"
} else if (model_to_run == "m3"){
  stan_file <- "stan_programs/stage1_covar.stan"
} else {
  cat("Invalid model name.")
}


## functions ----
mkdir_p <- function(dir_name) {
  dir.create(dir_name, showWarnings = FALSE, recursive = TRUE)
}

get_random_seed <-
  function(seed_file = paste0('./seed.rds')) {
    ## Generates and saves a random seed (with the model timestamp as the name)
    ## so that we can keep track of the seeds we use.
    if (file.exists(seed_file)) {
      random_seed <- readRDS(seed_file)
    } else {
      random_seed <- sample(.Machine$integer.max, 1)
      saveRDS(random_seed, file = seed_file)
    }
    return(random_seed)
  }


## Modeling parameters ----
##  Naming
tstamp <- format(Sys.time(), format = "%Y%m%d-%H%M")

# make directories to store the results
mkdir_p(paste0(path_mod, 'model_run_', tstamp))
random_seed <- get_random_seed(paste0(path_mod, 'model_run_', tstamp, '/seed.rds'))
model_name <- 'model'

# print tstamp and model (so sbatch output can be linked to model results)
paste0("Model time stamp: ", tstamp)

##  Run parameters
n_chains <- 4
n_iter <- 20000 # 5000
n_burnin <- floor(n_iter / 2)
n_thin <- 40
verbose_flag <- FALSE

## Load data ----

if(dual){
  ratios_df <- read_rds(paste0("data/symlinks/scratch/", outcome_to_run, "-dual_ratios_df.rds"))
} else {
  ratios_df <- read_rds(paste0("data/symlinks/scratch/", outcome_to_run, "_ratios_df.rds"))
}
county_adj_sparse_list <- read_rds('data/symlinks/scratch/county_adj_sparse_list.rds')


#----- make sure data is still in the correct order
# must be in this order to correspond to adjacency matrix

# sort data by race, and within race by county (as numeric)
ratios_df %<>%
  arrange(race, county)


#----- get state_mat_idx (state indicators for each county)

# since this model is combined by race, the matrix has n rows

# get state for each county
state_df <- ratios_df %>%
  select(county, s_idx) %>%
  distinct()

# get dummy cols for state
state_mat <- model.matrix(~factor(s_idx) - 1, data = state_df)
dim(state_mat) # 49 unique "states" (48 + DC)
write_rds(state_mat, "data/symlinks/scratch/state_mat_stage1.rds")

# read scaling factor from previous script
scaling_factor <- read_rds("data/intermediate/scaling_factor.rds")

# get a new dataframe for combined white & black
ratios_df_comb <- ratios_df %>%
  select(county, person_years, expected_stage1, observed,
         c_idx, s_idx,
         house_price_income_ratio, pm25) %>%
  group_by(county) %>%
  summarise(person_years_total = sum(person_years),
            expected_stage1_total = sum(expected_stage1),
            observed_total = sum(observed),
            c_idx = first(c_idx),
            s_idx = first(s_idx),
            house_price_income_ratio = first(house_price_income_ratio),
            pm25 = first(pm25))
if(dual){
  write_rds(ratios_df_comb, paste0("data/symlinks/scratch/", outcome_to_run, "-dual_combined_data.rds"))
} else {
  write_rds(ratios_df_comb, paste0("data/symlinks/scratch/", outcome_to_run, "_combined_data.rds")) 
}



## Get the data in order ----
# note: covariates will be added in later
stan_list  <-
  list(
    # number of states
    s = length(unique(ratios_df$s_idx)),
    # number of areas
    n = length(county_adj_sparse_list$D_sparse),
    # population_years
    y = ratios_df_comb$observed_total,
    # log of expected (note: must take log after adding black + white!)
    log_offset = log(ratios_df_comb$expected_stage1_total),
    
    # n*s matrix with state indicators
    state_mat_idx = state_mat,
    
    # number of edges
    W_n = nrow(county_adj_sparse_list$W_sparse),
    # first column of edge list
    W_adj1 = county_adj_sparse_list$W_sparse[,1],
    # second column of edge list
    W_adj2 = county_adj_sparse_list$W_sparse[,2],
    
    # scaling factor
    scaling_factor = scaling_factor
  )   


## copy stan file into model_run ----
# path for new file
temp_stan_file <- paste0(path_mod, 'model_run_', tstamp, '/temp_file.stan')
# copy stan file (in analysis folder) into a new file at this path
file.copy(stan_file, temp_stan_file)

rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())

if(model_to_run == "m1"){
  
  fit <- stan(
    file = temp_stan_file,
    data = stan_list, 
    thin = n_thin,
    iter = n_iter,
    warmup = n_burnin,
    chains = 4, 
    verbose = verbose_flag,
    save_dso = TRUE,
    seed = 1, 
    refresh = n_iter / 100,
    # sample files avoid storing everything in memory
    sample_file = paste0(path_mod, '/model_run_', tstamp, '/sample_file')
  )

} else if(model_to_run == "m2"){
  
  # specify p (number of covariates) in stan data list
  stan_list$p <- 1
  
  # get mean-centered HPI
  centered_hpi <- (ratios_df_comb$house_price_income_ratio -
                     mean(ratios_df_comb$house_price_income_ratio, na.rm = TRUE))
  
  # format covariate as matrix and add to stan data list
  stan_list$covar_mat <- as.matrix(centered_hpi, ncol = 1)
  
  fit <- stan(
    file = temp_stan_file,
    data = stan_list, 
    thin = n_thin,
    iter = n_iter,
    warmup = n_burnin,
    chains = 4, 
    verbose = verbose_flag,
    save_dso = TRUE,
    seed = 1, 
    refresh = n_iter / 100,
    sample_file = paste0(path_mod, '/model_run_', tstamp, '/sample_file')
  )
  
} else if(model_to_run == "m3"){
  
  # specify p (number of covariates) in stan data list
  stan_list$p <- 1
  
  # get mean-centered PM2.5
  centered_pm25 <- (ratios_df_comb$pm25 -
                      mean(ratios_df_comb$pm25, na.rm = TRUE))
  
  # format covariate as matrix and add to stan data list
  stan_list$covar_mat <- as.matrix(centered_pm25, ncol = 1)
  
  fit <- stan(
    file = temp_stan_file,
    data = stan_list, 
    thin = n_thin,
    iter = n_iter,
    warmup = n_burnin,
    chains = 4, 
    verbose = verbose_flag,
    save_dso = TRUE,
    seed = 1, 
    refresh = n_iter / 100,
    sample_file = paste0(path_mod, '/model_run_', tstamp, '/sample_file')
  )

} else {
  cat("Invalid model name")
}


# write stanfit object
write_rds(fit, paste0(path_mod, 'model_run_', tstamp, 
                      '/stanfit_object_stage1_', outcome_to_run, 
                      "_", model_to_run, '.rds'))


## Remove the copy of the stan code and the compiled stan model ----
# temp stan file
file.remove(temp_stan_file)
# compiled model
# this path will be the same as temp_stan_file but ends in dot rds instead of dot stan
file.remove(paste0(path_mod, 'model_run_', tstamp, '/temp_file.rds'))
