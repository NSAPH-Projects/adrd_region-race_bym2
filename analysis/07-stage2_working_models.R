

# Choose which models to copy into "working" folder
# This allows me to fit lots of models and keep track of which ones I'm currently using


models <- c(paste0("data/models/stage2/", 
                   c("adrd_model_run_20250508-1426/stanfit_object_stage2_adrd.rds",
                     "adrd-dual_model_run_20250508-1425/stanfit_object_stage2_adrd-dual.rds",
                     "nonadrd_model_run_20250508-1427/stanfit_object_stage2_nonadrd.rds",
                     "nonadrd-dual_model_run_20250508-1427/stanfit_object_stage2_nonadrd-dual.rds")))

# copy all of these models into the working folder
file.copy(models, "data/models/working", overwrite = TRUE)


########################################################################
########################################################################


# # choose models to copy into "working" folder
# # this allows me to run lots of models and keep track of the ones I'm currently using
# # run this after fitting stage 2 models
# 
# # get paths to all the current working models
# 
# #dual = TRUE
# dual = FALSE
# 
# newdata_oldmod <- TRUE
# # #newdata_oldmod <- FALSE
# 
# #equal_weight <- TRUE
# equal_weight <- FALSE
# 
# #two_obs <- TRUE
# two_obs <- FALSE
# 
# if(equal_weight){
#   
#   adrd_stage2 <- paste0("results/models/stage2/equal_weight/adrd/", 
#                         c("m1/model_run_20250407-2036/stanfit_object_stage2_adrd_m1.rds"))
#   
#   # get all model names in one vector
#   models <- c(adrd_stage2)
#   
#   # copy all of these models into the working folder
#   file.copy(models, "results/models/working/equal_weight", overwrite = TRUE)
#   
# } else if(two_obs){
#   
#   adrd_stage2 <- paste0("results/models/stage2/two_obs/adrd/", 
#                         c("m1/model_run_20250409-1409/stanfit_object_stage2_adrd_m1.rds"))
#   
#   # get all model names in one vector
#   models <- c(adrd_stage2)
#   
#   # copy all of these models into the working folder
#   file.copy(models, "results/models/working/two_obs", overwrite = TRUE)
#   
# } else if(dual){
#   
#   adrd_stage2 <- paste0("results/models/dual/stage2/adrd/", 
#                         c("m1/model_run_20241212-1915/stanfit_object_stage2_adrd_m1.rds"))
#   
#   hosp_stage2 <- paste0("results/models/dual/stage2/hosp/", 
#                         c("m1/model_run_20250126-2142/stanfit_object_stage2_hosp_m1.rds"))
#   
#   allc_stage2 <- paste0("results/models/dual/stage2/allc/", 
#                         c("m1/model_run_20250124-2140/stanfit_object_stage2_allc_m1.rds"))
#   
#   # get all model names in one vector
#   models <- c(adrd_stage2, hosp_stage2, allc_stage2)
#   
#   # copy all of these models into the working folder
#   file.copy(models, "results/models/dual/working", overwrite = TRUE)
#   
# } else if (newdata_oldmod){
#   
#   adrd_stage2 <- paste0("results/models/stage2/newdata_oldmod/adrd/", 
#                         c("m1/model_run_20250402-2028/stanfit_object_stage2_adrd_m1.rds"))
#   
#   # get all model names in one vector
#   models <- c(adrd_stage2)
#   
#   # copy all of these models into the working folder
#   file.copy(models, "results/models/working/newdata_oldmod", overwrite = TRUE)
#   
# } else {
#   
#   #----- stage 2 -----#
#   
#   adrd_stage2 <- paste0("results/models/stage2/adrd/", 
#                         c("m1/model_run_20240507-1555/stanfit_object_stage2_adrd_m1.rds",
#                           "m2/model_run_20240712-0021/stanfit_object_stage2_adrd_m2.rds",
#                           "m3/model_run_20240712-0021/stanfit_object_stage2_adrd_m3.rds"))
#   
#   hosp_stage2 <- paste0("results/models/stage2/hosp/",
#                         c(#"m1/model_run_20240507-1555/stanfit_object_stage2_hosp_m1.rds",
#                           "m1/model_run_20250118-1330/stanfit_object_stage2_hosp_m1.rds",
#                           "m2/model_run_20240712-0021/stanfit_object_stage2_hosp_m2.rds",
#                           "m3/model_run_20240712-0021/stanfit_object_stage2_hosp_m3.rds"))
#   
#   allc_stage2 <- paste0("results/models/stage2/allc/",
#                         c("m1/model_run_20240910-1927/stanfit_object_stage2_allc_m1.rds",
#                           "m2/model_run_20240910-1927/stanfit_object_stage2_allc_m2.rds",
#                           "m3/model_run_20240910-1927/stanfit_object_stage2_allc_m3.rds"))
#   
#   resp_stage2 <- paste0("results/models/stage2/resp/",
#                         c("m1/model_run_20241009-0025/stanfit_object_stage2_resp_m1.rds"))
#   
#   # get all model names in one vector
#   models <- c(adrd_stage2, hosp_stage2, allc_stage2, resp_stage2)
#   
#   # copy all of these models into the working folder
#   file.copy(models, "results/models/working", overwrite = TRUE)
#   
# }
# 
