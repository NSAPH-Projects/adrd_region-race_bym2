## Load libraries ----
library(tidyverse)
library(magrittr)
library(rstan)

# note: if model results are in two folders (different time stamps), move stanfit objects into the first folder

# specify folders with model results I want to use

folder_path <- c(paste0("results/models/hosp/m2/model_run_20240314/"))

# specify names to associate with each 
folder_names <- c(paste0("hosp_m", c(1:3)), paste0("hosp_m", c(2)))

# loop through folders
for (i in 1:length(folder_path)) {
  
  # get files that start with "stanfit_object_"
  stanfit_files <- grep("^stanfit_object_", list.files(folder_path[i]), value = TRUE)
  
  print(paste0("Model: ", folder_names[i], ", n chains: ", length(stanfit_files)))
  
  # read these files into a list
  stanfit_list <- list()
  
  # loop through available chains
  for (j in 1:length(stanfit_files)) {
    stanfit_list[[j]] <- read_rds(paste0(folder_path[i], stanfit_files[j]))
  }
  
  # Convert the list of model fits to a stan fit object
  stanfit_object <- sflist2stanfit(stanfit_list)
  
  # save for scripts 5 and 6
  write_rds(stanfit_object, file = paste0("results/models/working/", 
                                          "stanfit_object_", folder_names[i], ".rds"))
}

