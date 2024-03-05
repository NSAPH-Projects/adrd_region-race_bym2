#!/bin/bash
#SBATCH -p fasse # partition (queue)
#SBATCH -c 8 # number of cores
#SBATCH --mem=32GB # memory pool for all cores
#SBATCH -t 6-12:00 # time (D-HH:MM)

#SBATCH --array=1-8 # how many tasks in the array
#SBATCH -o slurm-%j-%a.out

singularity exec ../rstan_latest.sif Rscript --vanilla analysis/03-adrd_run_m4.R $SLURM_ARRAY_TASK_ID