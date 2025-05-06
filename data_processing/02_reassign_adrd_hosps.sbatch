#!/bin/bash
#SBATCH -p fasse # partition (queue)
#SBATCH -c 20 # number of cores
#SBATCH --mem=90GB # memory pool for all cores
#SBATCH -t 10:00:00 # time (D-HH:MM)
#SBATCH -o slurm-adm_ids-%j.out

# set R packages and rstudio server singularity image locations
my_packages=${HOME}/R/ifxrstudio/RELEASE_3_16
rstudio_singularity_image="/n/singularity_images/informatics/ifxrstudio/ifxrstudio:RELEASE_3_16.sif"

# run myscript.R using RStudio Server signularity image
singularity exec --cleanenv --env R_LIBS_USER=${my_packages} ${rstudio_singularity_image} Rscript --vanilla data_processing/02_reassign_adrd_hosps.R 