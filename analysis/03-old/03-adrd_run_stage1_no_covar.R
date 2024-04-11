## load packages ----
library(tidyverse)
library(magrittr)
library(rstan)

# path to store model results
path_mod <- "results/models/adrd/m1/stage1/"

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
tstamp <- format(Sys.time(), format = "%Y%m%d-%H%M%S")
#tstamp <- format(Sys.time(), format = "%Y%m%d")

mkdir_p(paste0(path_mod, 'model_run_', tstamp))
model_name <- 'model'
stan_file <- 'analysis/stan_code/stage1_no_covar.stan'
random_seed <- get_random_seed(paste0(path_mod, 'model_run_', tstamp, '/seed.rds'))

# print tstamp (so sbatch output can be linked to model results)
paste0("Model time stamp: ", tstamp)
paste0("Model: ADRD, m1")

##  Run parameters
#n_chains <- 4
n_iter <- 100
n_burnin <- floor(n_iter / 2)
#n_thin <- 40
n_thin <- 10
verbose_flag <- FALSE
#dont_save_pars = c("v_unstr", "u_str_unscaled", "u_str")

##  Search
# a_delta = .9 # default = .8
# t_depth = 15    # max tree depth, default = 10

## Load data ----
adrd_ratios_df <- read_rds('data/symlinks/scratch/adrd_ratios_df.rds')
county_adj_sparse_list <- read_rds('data/symlinks/scratch/county_adj_sparse_list.rds')


#----- make sure data is still in the correct order

# must be in this order to correspond to adjacency matrix

# sort ADRD data by race, and within race by county (as numeric)
adrd_ratios_df %<>%
  arrange(race, county)


#----- get state_mat_idx (state indicators for each county)

# since this model is combined by race, the matrix has n rows

# get state for each county
state_df <- adrd_ratios_df %>%
  select(county, s_idx) %>%
  distinct()

# get dummy cols for state
state_mat <- model.matrix(~factor(s_idx) - 1, data = state_df)
dim(state_mat) # 49 unique "states" (48 + DC)

# read scaling factor from previous script
scaling_factor <- 0.64524

# get a new dataframe for combined white & black
adrd_ratios_df_comb <- adrd_ratios_df %>%
  select(county, person_years, expected, observed,
         c_idx, s_idx) %>%
  group_by(county) %>%
  summarise(person_years_total = sum(person_years),
            expected_total = sum(expected),
            observed_total = sum(observed),
            c_idx = first(c_idx),
            s_idx = first(s_idx))


## Get the data in order ----
adrd_stan_list  <-
  list(
    # number of states
    s = length(unique(adrd_ratios_df$s_idx)),
    # number of areas
    n = length(county_adj_sparse_list$D_sparse),
    # population_years
    y = adrd_ratios_df_comb$observed_total,
    # log of expected (note: must take log after adding black + white!)
    log_offset = log(adrd_ratios_df_comb$expected_total),
    
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
# args = commandArgs(trailingOnly=TRUE)

#--- fit a single chain (args[1] will use a different chain ID each time)
fit <- stan(
  file = new_stan_file,
  data = adrd_stan_list, 
  thin = n_thin,
  iter = n_iter,
  warmup = n_burnin,
  chains = 4, 
  verbose = verbose_flag,
  # pars = dont_save_pars,
  # include = FALSE,
  save_dso = TRUE,
  seed = 1, 
  # control = list(adapt_delta = a_delta,
  #                max_treedepth = t_depth),
  refresh = n_iter / 100,
  sample_file = paste0(path_mod, 'model_run_', tstamp,
                       '/sample_file')
)

## Save fit objects
write_rds(fit, paste0(path_mod, 'model_run_', tstamp, '/stanfit_object.rds'))

## Remove the compiled stan model ----
# this path will be the same as new_stan_file but ends in dot rds instead of dot stan
file.remove(paste0(path_mod, 'model_run_', tstamp, '/temp_file.rds'))
file.remove(new_stan_file)

