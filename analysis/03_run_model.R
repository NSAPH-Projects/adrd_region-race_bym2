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
                             f_time = tstamp,
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

summarize_stanfit <- function(stanfit,
                              pars = c("alpha",
                                       "beta",
                                       "delta",
                                       "nu",
                                       "psi",
                                       "phi",
                                       "sigma_u",
                                       "sigma_v",
                                       "state_s")) {
  ## Just a wrapper to get stanfit summary as a dataframe with better
  ## column names and for parameters we care about.
  df <-
    as.data.frame(rstan::summary(stanfit, pars = pars)$summary)
  return(df)
}

## Modeling parameters ----
##  Naming
tstamp <- format(Sys.time(), format = "%Y%m%d_%H%M%S")
mkdir_p(paste0('./models/model_run_', tstamp))
model_name <- 'm0s_cp_reg_25k_4c_4t_995d'
#model_file <- 'm0s_cp_reg_25k_4c_4t_995d'
stan_file <- './models/m0s_no_covar.stan'
random_seed <- get_random_seed(paste0('./models/model_run_', tstamp,
                                      '/seed_', tstamp, '.rds'))

##  Run parameters
n_chains <- 8
n_iter <- 500
n_burnin <- floor(n_iter / 2)
n_thin <- 40
verbose_flag <- FALSE
dont_save_pars = c("v_unstr", "u_str_unscaled", "u_str")

##  Search
a_delta = .995  # default = .8
t_depth = 35    # max tree depth, default = 10

## Load data ----
adrd_rates_df <- read_rds('../data/intermediate/adrd_rates_df.rds')
county_fips_df <- read_rds('../data/intermediate/county_fips_df.rds')
county_adj_sparse_list <- read_rds('../data/intermediate/county_adj_sparse_list.rds')

## Prep data ----
adrd_rates_df %<>% 
  mutate(
    black = as.integer(if_else(race == 2, 1, 0)),
    expected = as.integer(ceiling(expected)) + 1, 
    observed = as.integer(ceiling(observed)) + 1
  ) %>% 
  left_join(
    county_fips_df %>% 
      mutate(county = as.integer(fipschar))
  )

## validate no NA ----
#summary(log(adrd_rates_df$expected))
#summary(log(adrd_rates_df$observed))

## Get the data in order ----
pre_df  <-
    list(
        m = nrow(adrd_rates_df),
        # number of observations
        s = length(unique(adrd_rates_df$s_idx)),
        # number of states
        n = length(county_adj_sparse_list$D_sparse),
        # number of areas
        y = adrd_rates_df$observed,
        # vector of observed (int)
        log_offset = log(adrd_rates_df$expected),
        # log of expected
        c_idx = adrd_rates_df$c_idx,
        # county index
        s_idx = adrd_rates_df$s_idx,
        # state index
        
        d1_idx = 1 - adrd_rates_df$black,
        # {1, 0} vector for dis_1
        d2_idx = adrd_rates_df$black,
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
write_rds(pre_df,
          paste0('./models/model_run_', tstamp, 
                 '/pre_df_', tstamp, '.rds'))

## Stan ----
## RStan options
## bug doesn't respect chain_id when auto_write == TRUE
## see: https://github.com/stan-dev/rstan/issues/294
# rstan_options(auto_write = FALSE)
rstan_options(auto_write = TRUE)
options(mc.cores = parallel::detectCores())

new_stan_file <- copy_rename_stan(stan_file)
premature_fit <- stan(
    file = new_stan_file,
    model_name = model_name,
    data = pre_df,
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

## Save summary and fit objects ----
write_rds(premature_fit, 
          paste0('./models/model_run_', 
                 tstamp, 
                 '/stanfit_object.rds'))

prem_summary <- summarize_stanfit(
  premature_fit,
  pars = c(
    "alpha",
    "delta",
    "psi",
    "phi",
    "nu",
    "sigma_u",
    "sigma_v",
    "sigma_s"
  )
)

write_rds(prem_summary,
         paste0('./models/model_run_', 
                tstamp, 
                '/stanfit_summary.rds'))

## Move stan file into model_run ----
file.rename(from = new_stan_file,
            to = paste0('./models/model_run_', tstamp, '/',
                        substr(new_stan_file, 3, nchar(new_stan_file))))

## Remove the compiled stan model ----
file.remove(paste0(substr(new_stan_file, 1, nchar(new_stan_file) - 4), 'rds'))
