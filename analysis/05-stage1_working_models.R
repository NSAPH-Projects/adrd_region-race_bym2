
# choose models to copy into "working" folder
# this allows me to run lots of models and keep track of the ones I'm currently using
# run this after fitting stage 1 models, before fitting stage 2

# get paths to all the current working models


#----- stage 1 -----#

adrd_stage1 <- paste0("results/models/stage1/adrd/", 
                       c("m1/model_run_20240506-185054/stanfit_object_stage1_adrd_m1.rds"))

hosp_stage1 <- paste0("results/models/stage1/hosp/",
                      c("m1/model_run_20240506-185101/stanfit_object_stage1_hosp_m1.rds"))

# get all model names in one vector
models <- c(adrd_stage1, hosp_stage1)

# copy all of these models into the working folder
file.copy(models, "results/models/working", overwrite = TRUE)

