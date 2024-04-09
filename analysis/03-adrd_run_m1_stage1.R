## load packages ----
library(tidyverse)
library(magrittr)
library(rstan)
library(fastDummies)

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
tstamp <- format(Sys.time(), format = "%Y%m%d-%H")
#tstamp <- format(Sys.time(), format = "%Y%m%d")

mkdir_p(paste0(path_mod, 'model_run_', tstamp))
model_name <- 'model'
stan_file <- 'analysis/stan_code/bym2_stan_no_covar_combined.stan'
random_seed <- get_random_seed(paste0(path_mod, 'model_run_', tstamp, '/seed.rds'))

# print tstamp (so sbatch output can be linked to model results)
paste0("Model time stamp: ", tstamp)
paste0("Model: ADRD, m1")

##  Run parameters
#n_chains <- 4
n_iter <- 1000
n_burnin <- floor(n_iter / 2)
#n_thin <- 40
n_thin <- 10
verbose_flag <- FALSE
#dont_save_pars = c("v_unstr", "u_str_unscaled", "u_str")

##  Search
a_delta = .9 # default = .8
t_depth = 15    # max tree depth, default = 10

## Load data ----
adrd_ratios_df <- read_rds('data/symlinks/scratch/adrd_ratios_df.rds')
county_adj_sparse_list <- read_rds('data/symlinks/scratch/county_adj_sparse_list.rds')


######################################################
######################################################

#----- re-order the data

# sort ADRD data by race, and within race by state, and within state by county
# this is necessary for model fitting to work!
# adrd_ratios_df %<>%
#   arrange(race, s_idx, c_idx)
adrd_ratios_df %<>%
  arrange(county)

#----- get state_mat_idx

state_df_total <- adrd_ratios_df %>%
  select(county, s_idx) %>%
  distinct()

# get dummy cols for state
state_df_total <- dummy_cols(state_df_total, select_columns = "s_idx")

# make a matrix with only dummy cols
state_mat_total <- state_df_total %>%
  select(-c(county, s_idx)) %>%
  as.matrix()
dim(state_mat_total) # 49 unique "states" (48 + DC)


# #----- hard code variances for spatial random effects
# 
# ### load model results from previous m1
# # load list with all model results and bind into df
# pos_med <- read_rds(paste0("data/intermediate/adrd_pos_med.rds"))
# pos_med <- pos_med[[1]] # m1 only
# 
# # load less processed model results to get posterior median of nu for each state
# stanfit_samples <- read_rds("data/intermediate/adrd_stanfit_samples.rds")[[1]]
# nu <- colMeans(stanfit_samples$nu)
# 
# 
# # var(phi * delta + psi1)
# psi_scale1 <- pos_med %>%
#   filter(race == 1) %>%
#   mutate(scaled_phi_plus_psi1 = shared + specific) %>%
#   pull(scaled_phi_plus_psi1) %>%
#   var()
# 
# # var(phi / delta + psi2)
# psi_scale2 <- pos_med %>%
#   filter(race == 2) %>%
#   mutate(scaled_phi_plus_psi2 = shared + specific) %>%
#   pull(scaled_phi_plus_psi2) %>%
#   var()
# 
# # var(nu)
# nu_scale <- var(nu)
#   

#----- alternatively, estimate scaling factor with INLA

# library(devtools)
# 
# # install fmesher (dependency)
# install.packages("fmesher")
# remotes::install_github("inlabru-org/fmesher", ref = "stable")
# library(fmesher)
# 
# # install INLA
# install.packages("INLA", dependencies = TRUE)
# install.packages("INLA",repos=c(getOption("repos"),INLA="https://inla.r-inla-download.org/R/stable"), dep=TRUE)
# devtools::install_github(repo = "https://github.com/hrue/r-inla", ref = "stable", subdir = "rinla", build = FALSE)

scaling_factor <- 0.64524

# get a new dataframe for combined white & black
adrd_ratios_df_combined <- adrd_ratios_df %>%
  select(county, person_years, expected, observed,
         c_idx, s_idx) %>%
  group_by(county) %>%
  summarise(person_years_total = sum(person_years),
            expected_total = sum(expected),
            observed_total = sum(observed),
            c_idx = first(c_idx),
            s_idx = first(s_idx))

# now re-order again (because the order gets messed up)
# actually, I think the order was fine...
# adrd_ratios_df_combined %<>%
#   arrange(s_idx, c_idx)
adrd_ratios_df_combined %<>%
  arrange(county)


######################################################
######################################################


## Get the data in order ----
adrd_stan_list  <-
  list(
    #m = nrow(adrd_ratios_df),
    # number of observations
    s = length(unique(adrd_ratios_df$s_idx)),
    # number of states
    n = length(county_adj_sparse_list$D_sparse),
    # number of areas
    y = adrd_ratios_df_combined$observed_total,
    # population_years
    #pop = adrd_ratios_df$person_years,
    # vector of observed (int)
    log_offset = log(adrd_ratios_df_combined$expected_total),
    # log of expected
    # c_idx = adrd_ratios_df$c_idx,
    # # county index
    # s_idx = adrd_ratios_df$s_idx,
    # # state index
    state_mat_idx = state_mat_total,
    # m*s matrix with state indicators
    
    #d1_idx = 1 - adrd_ratios_df$black,
    # {1, 0} vector for dis_1
    #d2_idx = adrd_ratios_df$black,
    # {0, 1} vector for dis_2
    
    # psi_scale1 = psi_scale1,   # var(phi * delta + psi1)
    # psi_scale2 = psi_scale2,   # var(phi * delta + psi2)
    # nu_scale = nu_scale,       # var(nu)
    
    # Use return_sparse_parts(A) for these next ones
    #D_sparse = county_adj_sparse_list$D_sparse,
    # neighbors per node
    #W_sparse = county_adj_sparse_list$W_sparse,
    # adjacent pairs
    #lambda = county_adj_sparse_list$lambdas,
    # eigenvalues
    W_n = nrow(county_adj_sparse_list$W_sparse),
    # number of edges
    W_adj1 = county_adj_sparse_list$W_sparse[,1],
    # first column of edge list
    W_adj2 = county_adj_sparse_list$W_sparse[,2],
    # second column of edge list
    
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
  #pars = dont_save_pars,
  #include = FALSE,
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

# ## Remove the compiled stan model ----
# # this path will be the same as new_stan_file but ends in dot rds instead of dot stan
# file.remove(paste0(path_mod, 'model_run_', tstamp, '/temp_file.rds'))
# file.remove(new_stan_file)


