## load packages ----
library(tidyverse)
library(magrittr)
library(rstan)

# path to store model results
path_mod <- "results/models/adrd/m2/"

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
## Naming
#tstamp <- format(Sys.time(), format = "%Y%m%d_%H%M%S")
tstamp <- format(Sys.time(), format = "%Y%m%d_%H%M")


##### still gets a new number for each task :(
# # get files names from existing runs (without model_run_ at the beginning)
# existing_runs <- sub("^model_run_", "", list.files(path = path_mod, pattern = "^model_run_"))
# 
# if(length(existing_runs) == 0){
#   next_run <- 1
# }else{
#   # ignore whatever is after the first underscore
#   last_run <- str_split(existing_runs[length(existing_runs)], "_", n = 2)[[1]][1]
# 
#   # get the largest number already there and +1
#   next_run <- as.numeric(last_run) + 1
# }


mkdir_p(paste0(path_mod, 'model_run_', tstamp))
#mkdir_p(paste0(path_mod, 'model_run_', next_run, "_", tstamp))
model_name <- 'model'
stan_file <- 'analysis/stan_code/m2_HPI_ratio.stan'
random_seed <- get_random_seed(paste0(path_mod, 'model_run_', tstamp, '/seed.rds'))

# print tstamp (so sbatch output can be linked to model results)
paste0("Model time stamp: ", tstamp)

##  Run parameters
#n_chains <- 4
#n_chains <- 1
n_iter <- 10000
#n_iter <- 100
#n_burnin <- min(floor(n_iter / 2), 300)
n_burnin <- floor(n_iter / 2)
n_thin <- 40
verbose_flag <- FALSE
dont_save_pars = c("v_unstr", "u_str_unscaled", "u_str")

##  Search
a_delta = .995  # default = .8
t_depth = 35    # max tree depth, default = 10
# a_delta = .99  # default = .8
# t_depth = 1000   # max tree depth, default = 10

## Load data ----
adrd_ratios_df <- read_rds('data/symlinks/scratch/adrd_ratios_df.rds')
county_adj_sparse_list <- read_rds('data/symlinks/scratch/county_adj_sparse_list.rds')


#############################################################
#############################################################

# ## try restricting the analysis to one state (Alabama)
# 
# adrd_ratios_df <- adrd_ratios_df %>%
#   filter(s_idx == 1)
# 
# county_adj_sparse_list$D_sparse <- county_adj_sparse_list$D_sparse[1:67]
# 
# county_adj_sparse_list$W_sparse  %<>%
#   as.data.frame() %>%
#   filter(row %in% adrd_ratios_df$c_idx & col %in% adrd_ratios_df$c_idx) %>%
#   as.matrix()
# 
# county_adj_sparse_list$lambdas <- county_adj_sparse_list$lambdas[1:67]
# 
# county_adj_sparse_list$W_n <- nrow(county_adj_sparse_list$W_sparse)


#############################################################
#############################################################



# ## Mean center income and change to per $10,000 ----
# income <- (adrd_ratios_df$med_house_income -
#              mean(adrd_ratios_df$med_house_income, na.rm = TRUE)) / 10000

# Mean center (change name here and in model to HPI)
income <- (adrd_ratios_df$house_price_income_ratio -
             mean(adrd_ratios_df$house_price_income_ratio, na.rm = TRUE))

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

# need to save results of each chain before I combine them (some may not finish running)
# (so they are saved even if they don't all finish running)

# fit <- stan(
#   file = new_stan_file,
#   model_name = model_name,
#   data = adrd_stan_list,
#   thin = n_thin,
#   iter = n_iter,
#   warmup = n_burnin,
#   chains = n_chains,
#   verbose = verbose_flag,
#   pars = dont_save_pars,
#   include = FALSE,
#   save_dso = TRUE,
#   seed = random_seed,
#   control = list(adapt_delta = a_delta,
#                  max_treedepth = t_depth),
#   refresh = n_iter / 100,
#   sample_file = paste0(path_mod, 'model_run_', tstamp, '/sample_file')
# )

# ## Save fit objects
# write_rds(fit, paste0(path_mod, 'model_run_', tstamp, '/stanfit_object.rds'))

# ## Remove the compiled stan model
# # this path will be the same as new_stan_file but ends in rds instead of stan
# file.remove(paste0(path_mod, 'model_run_', tstamp, '/temp_file.rds'))
# file.remove(new_stan_file)
# not sure I want to do this with array
