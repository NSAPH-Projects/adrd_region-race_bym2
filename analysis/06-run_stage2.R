
#----- RUN STAGE 2 -----#

## load packages ----
library(tidyverse)
library(magrittr)
library(rstan)

########## user input ########## 

# outcome (adrd or nonadrd)
#outcome <- "adrd"
outcome <- "nonadrd"

# incorporating Medicaid eligibility into expected counts?
dual <- TRUE # standardize by sex, age, Medicaid
#dual <- FALSE # standardize by sex, age

#------------------------------------#

# paste parameters in slurm output
paste0(outcome)
paste0("dual = ", dual)

# get path to location to store model
path_mod <- paste0("data/models/stage2/")

# path to stan program
stan_file <- "stan_programs/model_stage2.stan"


## functions ----
mkdir_p <- function(dir_name) {
  dir.create(dir_name, showWarnings = FALSE, recursive = TRUE)
}

get_random_seed <-
  function(seed_file = paste0('./seed.rds')) {
    ## Generates and saves a random seed (with the model timestamp as the name)
    ## so that we can keep track of the seeds we use.
    random_seed <- sample(.Machine$integer.max, 1)
    saveRDS(random_seed, file = seed_file)
    return(random_seed)
  }

## Modeling parameters ----
##  Naming
tstamp <- format(Sys.time(), format = "%Y%m%d-%H%M")

# make directories to store the results

if(dual){
  dir_tstamp <- paste0(path_mod, outcome, '-dual_model_run_', tstamp)
} else {
  dir_tstamp <- paste0(path_mod, outcome, '_model_run_', tstamp)
}
mkdir_p(dir_tstamp)
random_seed <- get_random_seed(paste0(dir_tstamp, '/seed.rds'))
model_name <- 'model'

# print tstamp and model (so sbatch output can be linked to model results)
paste0("Model time stamp: ", tstamp)

##  Run parameters
n_chains <- 4
n_iter <- 20000
n_burnin <- floor(n_iter / 2)
n_thin <- 40
verbose_flag <- FALSE

## Load data ----

if(dual){
  ratios_df <- read_rds(paste0("data/symlinks/scratch/", outcome_to_run, "-dual_ratios_df.rds"))
} else {
  ratios_df <- read_rds(paste0("data/symlinks/scratch/", outcome_to_run, "_ratios_df.rds"))
}

# load county adjacency
county_adj_sparse_list <- read_rds('data/symlinks/scratch/county_adj_sparse_list.rds')


#----- make sure data is still in the correct order
# must be in this order to correspond to adjacency matrix

# sort data by race, and within race by county (as numeric)
ratios_df %<>%
  arrange(race, county)


#----- get state_mat_idx (state indicators for each county)

# read in state matrix indicators written in stage 1
state_mat <- read_rds("data/symlinks/scratch/state_mat.rds")

# read scaling factor from previous script
scaling_factor <- read_rds("data/intermediate/scaling_factor.rds")


#----- read results from stage 1 to feed into stage 2

# read model results from stage 1
if(dual){
  stage1_results <- read_rds(paste0("data/models/working/stanfit_object_stage1_", 
                                    outcome, "-dual.rds"))
} else {
  stage1_results <- read_rds(paste0("data/models/working/stanfit_object_stage1_", 
                                    outcome, ".rds"))
}

# extract matrix of phis and get column means (posterior means)
# note: these are the raw phis, NOT the transformed phis that are mapped later
phi_hats <- extract(stage1_results)$phi %>% colMeans()


## Get the data in order ----
stan_list  <-
  list(
    # number of observations
    m = nrow(ratios_df),
    # number of states
    s = length(unique(ratios_df$s_idx)),
    # number of areas
    n = length(county_adj_sparse_list$D_sparse),
    # population_years
    y = ratios_df$observed,
    # log of expected
    log_offset = log(ratios_df$expected_stage2),
    
    # m*s matrix with state indicators
    state_mat_idx = state_mat,
    
    # {1, 0} indicator for White
    d1_idx = 1 - ratios_df$black,
    # {0, 1} indicator for Black
    d2_idx = ratios_df$black,
    
    # fixed phi hats from stage 1
    phi_hat = phi_hats,
    
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
temp_stan_file <- paste0(dir_tstamp, '/temp_file.stan')
# copy stan file (in analysis folder) into a new file at this path
file.copy(stan_file, temp_stan_file)

rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())


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
  # sample files to avoid storing everything in memory
  sample_file = paste0(dir_tstamp, '/sample_file')
)


# write stanfit object
if(dual){
  write_rds(fit, paste0(dir_tstamp, '/stanfit_object_stage2_', outcome, '.rds'))
} else {
  write_rds(fit, paste0(dir_tstamp, '/stanfit_object_stage2_', outcome, '-dual.rds'))
}


## Remove the copy of the stan code and the compiled stan model ----
# temp stan file
file.remove(temp_stan_file)
# compiled model
# this path will be the same as temp_stan_file but ends in dot rds instead of dot stan
file.remove(paste0(dir_tstamp, '/temp_file.rds'))
