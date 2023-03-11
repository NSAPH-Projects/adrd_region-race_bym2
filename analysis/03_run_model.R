## load packages ----
library(tidyverse)
library(magrittr)
library(rstan)

## functions ----
mkdir_p <- function(dir_name) {
  dir.create(dir_name, showWarnings = FALSE, recursive = TRUE)
}

get_random_seed <-
  function(seed_file = paste0('./seed_', tstamp, '.rds')) {
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

copy_rename_stan <- function(orig_file,
                             f_time,
                             return_new_file = TRUE) {
  ## Function that copies a file, renames it, and returns new file
  ## Extract just the file name
  base_file <- basename(orig_file)
  
  new_file <-
    paste0('./', substr(base_file, 1, nchar(base_file) - 5),
           "_", f_time, ".stan")
  
  file.copy(orig_file, new_file, overwrite = TRUE)
  
  if (return_new_file) {
    return(new_file)
  }
}

## Modeling parameters ----
##  Naming
tstamp <- format(Sys.time(), format = "%Y%m%d_%H%M%S")
mkdir_p(paste0('./models/model_run_', tstamp))
model_name <- 'm0_no_covar_invdelta'
stan_file <- './models/m0s_no_covar_invdelta.stan'
random_seed <- get_random_seed(paste0('./models/model_run_', tstamp,
                                      '/seed_', tstamp, '.rds'))

##  Run parameters
n_chains <- 1
n_iter <- 1300
n_burnin <- min(floor(n_iter / 2), 300)
n_thin <- 10
verbose_flag <- FALSE
dont_save_pars = c("v_unstr", "u_str_unscaled", "u_str")

##  Search
a_delta = .995  # default = .8
t_depth = 35    # max tree depth, default = 10

## Load data ----
adrd_ratios_df <- read_rds('../data/intermediate/adrd_ratios_df.rds')
county_adj_sparse_list <- read_rds('../data/intermediate/county_adj_sparse_list_.rds')

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
        log_offset = log(adrd_ratios_df$expected),
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
          paste0('./models/model_run_', tstamp, 
                 '/adrd_stan_list_', tstamp, '.rds'))

## Stan ----
## RStan options
## bug doesn't respect chain_id when auto_write == TRUE
## see: https://github.com/stan-dev/rstan/issues/294
# rstan_options(auto_write = FALSE)

## copy and move stan file into model_run ----
new_stan_file <- copy_rename_stan(stan_file, f_time = tstamp)
file.rename(from = new_stan_file,
            to = paste0('./models/model_run_', tstamp, '/',
                        substr(new_stan_file, 3, nchar(new_stan_file))))

rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())

fit <- stan(
    file = new_stan_file,
    model_name = model_name,
    data = adrd_stan_list,
    thin = n_thin,
    iter = n_iter,
    warmup = n_burnin,
    chains = n_chains,
    verbose = verbose_flag,
    pars = dont_save_pars,
    include = FALSE,
    save_dso = TRUE,
    seed = random_seed,
    control = list(adapt_delta = a_delta,
                   max_treedepth = t_depth),
    refresh = n_iter / 100,
    sample_file = paste0('./models/model_run_', tstamp,
                         '/sample_file')
)

## Save fit objects ----
write_rds(fit, 
          paste0('./models/model_run_', 
                 tstamp, 
                 '/stanfit_object.rds'))



## Remove the compiled stan model ----
file.remove(paste0(substr(new_stan_file, 1, nchar(new_stan_file) - 4), 'rds'))
