
# choose models to copy into "working" folder
# this allows me to run lots of models and keep track of the ones I'm currently using
# run this after fitting stage 2 models

# get paths to all the current working models


#----- stage 2 -----#

adrd_stage2 <- paste0("results/models/stage2/adrd/", 
                      c("m1/model_run_20240507-1555/stanfit_object_stage2_adrd_m1.rds",
                        "m2/model_run_20240712-0021/stanfit_object_stage2_adrd_m2.rds",
                        "m3/model_run_20240712-0021/stanfit_object_stage2_adrd_m3.rds"))

hosp_stage2 <- paste0("results/models/stage2/hosp/",
                      c("m1/model_run_20240507-1555/stanfit_object_stage2_hosp_m1.rds",
                        "m2/model_run_20240712-0021/stanfit_object_stage2_hosp_m2.rds",
                        "m3/model_run_20240712-0021/stanfit_object_stage2_hosp_m3.rds"))

# get all model names in one vector
models <- c(adrd_stage2, hosp_stage2)

# copy all of these models into the working folder
file.copy(models, "results/models/working", overwrite = TRUE)

