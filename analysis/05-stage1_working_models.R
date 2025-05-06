
# Choose which models to copy into "working" folder
# This allows me to fit lots of models and keep track of which ones I'm currently using


models <- c(paste0("data/models/stage1/", c("adrd_model_run_20250506-1610",
                                            "adrd-dual_model_run_20250506-1610",
                                            "nonadrd_model_run_20250506-1610",
                                            "nonadrd-dual_model_run_20250506-1611")))

# copy all of these models into the working folder
file.copy(models, "results/models/working", overwrite = TRUE)



########################################################################
########################################################################

# # get paths to all the current working models
# 
# #dual = TRUE
# #dual = FALSE
# 
# # newdata_oldmod <- TRUE
# # #newdata_oldmod <- FALSE
# 
# #equal_weight <- TRUE
# equal_weight <- FALSE
# 
# two_obs <- TRUE
# 
# 
# if(equal_weight){
#   
#   adrd_stage1 <- paste0("results/models/stage1/equal_weight/adrd/", 
#                         c("m1/model_run_20250404-1849/stanfit_object_stage1_adrd_m1.rds"))
#     
#   # get all model names in one vector
#   models <- c(adrd_stage1)
#   
#   # copy all of these models into the working folder
#   file.copy(models, "results/models/working/equal_weight", overwrite = TRUE)
#   
# } else if(two_obs){
#   
#   adrd_stage1 <- paste0("results/models/stage1/two_obs/adrd/", 
#                         c("m1/model_run_20250408-1832/stanfit_object_stage1_adrd_m1.rds"))
#   
#   # get all model names in one vector
#   models <- c(adrd_stage1)
#   
#   # copy all of these models into the working folder
#   file.copy(models, "results/models/working/two_obs", overwrite = TRUE)
#   
# } else if(dual){
#   
#   adrd_stage1 <- paste0("results/models/dual/stage1/adrd/", 
#                         c("m1/model_run_20241212-1704/stanfit_object_stage1_adrd_m1.rds"))
#   
#   hosp_stage1 <- paste0("results/models/dual/stage1/hosp/", 
#                         c("m1/model_run_20250124-2220/stanfit_object_stage1_hosp_m1.rds"))
#   
#   allc_stage1 <- paste0("results/models/dual/stage1/allc/", 
#                         c("m1/model_run_20250123-1856/stanfit_object_stage1_allc_m1.rds"))
#   
#   # get all model names in one vector
#   models <- c(adrd_stage1, hosp_stage1, allc_stage1)
#   
#   # copy all of these models into the working folder
#   file.copy(models, "results/models/dual/working", overwrite = TRUE)
#   
# } else{
#   
#   #----- stage 1 -----#
#   
#   adrd_stage1 <- paste0("results/models/stage1/adrd/", 
#                         c("m1/model_run_20240506-185054/stanfit_object_stage1_adrd_m1.rds",
#                           "m2/model_run_20240711-1958/stanfit_object_stage1_adrd_m2.rds",
#                           "m3/model_run_20240711-1959/stanfit_object_stage1_adrd_m3.rds"))
#   
#   hosp_stage1 <- paste0("results/models/stage1/hosp/",
#                         c(#"m1/model_run_20240506-185101/stanfit_object_stage1_hosp_m1.rds",
#                           "m1/model_run_20250118-0250/stanfit_object_stage1_hosp_m1.rds",
#                           "m2/model_run_20240711-2000/stanfit_object_stage1_hosp_m2.rds",
#                           "m3/model_run_20240711-2000/stanfit_object_stage1_hosp_m3.rds"))
#   
#   allc_stage1 <- paste0("results/models/stage1/allc/",
#                         c("m1/model_run_20240910-1434/stanfit_object_stage1_allc_m1.rds",
#                           "m2/model_run_20240910-1434/stanfit_object_stage1_allc_m2.rds",
#                           "m3/model_run_20240910-1434/stanfit_object_stage1_allc_m3.rds"))
#   
#   resp_stage1 <- paste0("results/models/stage1/resp/",
#                         c("m1/model_run_20241008-2055/stanfit_object_stage1_resp_m1.rds"))
#   
#   # get all model names in one vector
#   models <- c(adrd_stage1, hosp_stage1, allc_stage1, resp_stage1)
#   
#   # copy all of these models into the working folder
#   file.copy(models, "results/models/working", overwrite = TRUE)
#   
# }
# 
# 
# 
