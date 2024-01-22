## load packages ----
library(tidyverse)
library(magrittr)
library(rstan)

## functions ----
mkdir_p <- function(dir_name) {
  dir.create(dir_name, 
             #showWarnings = FALSE, 
             recursive = TRUE)
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
tstamp <- format(Sys.time(), format = "%Y%m%d_%H%M%S")
mkdir_p(paste0('results/models/m1/model_run_', tstamp))
model_name <- 'model'
stan_file <- 'analysis/m1_cost_ratio.stan'
random_seed <- get_random_seed(paste0('results/models/m1/model_run_', tstamp,
                                      '/seed.rds'))

##  Run parameters
n_chains <- 4
#n_iter <- 1300
n_iter <- 1000
n_burnin <- min(floor(n_iter / 2), 300)
n_thin <- 10
verbose_flag <- FALSE
dont_save_pars = c("v_unstr", "u_str_unscaled", "u_str")

##  Search
a_delta = .995  # default = .8
t_depth = 35    # max tree depth, default = 10
# a_delta = .99  # default = .8
# t_depth = 1000   # max tree depth, default = 10

## Load data ----
adrd_ratios_df <- read_rds('data/symlinks/temp/adrd_ratios_df.rds')
county_adj_sparse_list <- read_rds('data/symlinks/temp/county_adj_sparse_list.rds')

#########
# TEMPORARY -- merge in income (should be done in previous script)

adrd_county_df <- read_rds("data/symlinks/temp/adrd_county_df.rds")

# merge back in median household income (eventually use ratio with cost)
adrd_ratios_df %<>%
  left_join(adrd_county_df %>%
              dplyr::select(county, med_house_income) %>% distinct(),
            by = "county")

## Mean center income and change to per $10,000 ----
income <- (adrd_ratios_df$med_house_income -
             mean(adrd_ratios_df$med_house_income, na.rm = TRUE)) / 10000

#########


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
    
    income = income,
    
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
          paste0('results/models/m1/model_run_', tstamp, 
                 '/adrd_stan_list.rds'))

## copy stan file into model_run ----
new_stan_file <- paste0('results/models/m1/model_run_', tstamp, '/m_', tstamp, '.stan')
file.copy(stan_file, 
          new_stan_file)

## Stan ----
## RStan options
## bug doesn't respect chain_id when auto_write == TRUE
## see: https://github.com/stan-dev/rstan/issues/294
# rstan_options(auto_write = FALSE)
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
  sample_file = paste0('results/models/m1/model_run_', tstamp,
                       '/sample_file')
)

## Save fit objects ----
write_rds(fit, 
          paste0('results/models/m1/model_run_', 
                 tstamp, 
                 '/stanfit_object.rds'))



## Remove the compiled stan model ----
file.remove(paste0('results/models/m1/model_run_', tstamp, '/m_', tstamp, '.rds'))
file.remove(new_stan_file)
