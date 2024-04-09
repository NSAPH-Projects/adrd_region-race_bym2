## load packages ----
library(tidyverse)
library(magrittr)
library(rstan)

# path to store model results
path_mod <- "results/models/adrd/m1/"

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
#tstamp <- format(Sys.time(), format = "%Y%m%d_%H%M%S")
tstamp <- format(Sys.time(), format = "%Y%m%d")

mkdir_p(paste0(path_mod, 'model_run_', tstamp))
model_name <- 'model'
stan_file <- 'analysis/stan_code/m1_no_covar.stan'
random_seed <- get_random_seed(paste0(path_mod, 'model_run_', tstamp, '/seed.rds'))

# print tstamp (so sbatch output can be linked to model results)
paste0("Model time stamp: ", tstamp)
paste0("Model: ADRD, m1")

##  Run parameters
#n_chains <- 4
n_iter <- 10000
n_burnin <- floor(n_iter / 2)
n_thin <- 40
verbose_flag <- FALSE
dont_save_pars = c("v_unstr", "u_str_unscaled", "u_str")

##  Search
a_delta = .995  # default = .8
t_depth = 35    # max tree depth, default = 10

## Load data ----
adrd_ratios_df <- read_rds('data/symlinks/scratch/adrd_ratios_df.rds')
county_adj_sparse_list <- read_rds('data/symlinks/scratch/county_adj_sparse_list.rds')

## Get the data in order ----
adrd_stan_list  <-
    list(
        m = nrow(adrd_ratios_df),
        # number of observations
        s = length(unique(adrd_ratios_df$s_idx)),
        # number of states
        n = length(county_adj_sparse_list$D_sparse),
        # number of areas
        y = adrd_ratios_df$observed,
        # population_years
        pop = adrd_ratios_df$person_years,
        # vector of observed (int)
        log_offset = adrd_ratios_df$log_expected,
        # log of expected
        c_idx = adrd_ratios_df$c_idx,
        # county index
        s_idx = adrd_ratios_df$s_idx,
        # state index
        
        d1_idx = 1 - adrd_ratios_df$black,
        # {1, 0} vector for dis_1
        d2_idx = adrd_ratios_df$black,
        # {0, 1} vector for dis_2
        
        # Use return_sparse_parts(A) for these next ones
        D_sparse = county_adj_sparse_list$D_sparse,
        # neighbors per node
        W_sparse = county_adj_sparse_list$W_sparse,
        # adjacent pairs
        lambda = county_adj_sparse_list$lambdas,
        # eigenvalues
        W_n = nrow(county_adj_sparse_list$W_sparse)
    )   # number of edges

## Save the passed data in case we need it later ----
write_rds(adrd_stan_list,
          paste0(path_mod, 'model_run_', tstamp, '/adrd_stan_list.rds'))

## copy stan file into model_run ----
# path for new file
new_stan_file <- paste0(path_mod, 'model_run_', tstamp, '/temp_file.stan')
# copy stan file (in analysis folder) into a new file at this path
file.copy(stan_file, new_stan_file)

## Stan ----
## RStan options
## bug doesn't respect chain_id when auto_write == TRUE
## see: https://github.com/stan-dev/rstan/issues/294
# rstan_options(auto_write = FALSE)
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())

# get command line arguments and save in a list
args = commandArgs(trailingOnly=TRUE)

#--- fit a single chain (args[1] will use a different chain ID each time)
fit <- stan(
  file = new_stan_file,
  data = adrd_stan_list, 
  thin = n_thin,
  iter = n_iter,
  warmup = n_burnin,
  chains = 1, 
  verbose = verbose_flag,
  pars = dont_save_pars,
  include = FALSE,
  save_dso = TRUE,
  seed = 1, 
  chain_id = args[1],
  control = list(adapt_delta = a_delta,
                 max_treedepth = t_depth),
  refresh = n_iter / 100,
  sample_file = paste0(path_mod, 'model_run_', tstamp,
                       '/sample_file_', args[1])
)

## Save fit objects
write_rds(fit, paste0(path_mod, 'model_run_', tstamp, '/stanfit_object_', args[1], '.rds'))

# ## Remove the compiled stan model ----
# # this path will be the same as new_stan_file but ends in dot rds instead of dot stan
# file.remove(paste0(path_mod, 'model_run_', tstamp, '/temp_file.rds'))
# file.remove(new_stan_file)
