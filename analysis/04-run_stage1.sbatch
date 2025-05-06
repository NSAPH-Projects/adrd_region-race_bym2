#!/bin/bash
#SBATCH -p fasse # partition (queue)
#SBATCH -c 4 # number of cores
#SBATCH --mem=4GB # memory pool for all cores
#SBATCH -t 12:00:00 # time (D-HH:MM)
#SBATCH -o slurm-stage1-%j.out

# set R packages and rstudio server singularity image locations
my_packages=${HOME}/R/ifxrstudio/RELEASE_3_16
rstudio_singularity_image="/n/singularity_images/informatics/ifxrstudio/ifxrstudio:RELEASE_3_16.sif"

# run myscript.R using RStudio Server signularity image
singularity exec --cleanenv --env R_LIBS_USER=${my_packages} ${rstudio_singularity_image} Rscript --vanilla analysis/04-run_stage1.R