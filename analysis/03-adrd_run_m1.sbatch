#!/bin/bash
#SBATCH -p fasse # partition (queue)
#SBATCH -c 1 # number of cores
#SBATCH --mem=4GB # memory pool for all cores
#SBATCH -t 6-12:00 # time (D-HH:MM)

#SBATCH --array=1-8 # how many tasks in the array
#SBATCH -o slurm-adrd-m1-%j-%a.out

singularity exec ../rstan_latest.sif Rscript --vanilla analysis/03-adrd_run_m1.R $SLURM_ARRAY_TASK_ID