#!/bin/bash
#SBATCH -p fasse # partition (queue)
#SBATCH -c 8 # number of cores
#SBATCH --mem=100GB # memory pool for all cores
#SBATCH -t 6-12:00 # time (D-HH:MM)

singularity exec $HOME/apps/rstan_latest.sif Rscript --vanilla 03-adrd_run_m1.R
