#!/bin/bash
#SBATCH -p fasse # partition (queue)
#SBATCH -c 8 # number of cores
#SBATCH --mem=100GB # memory pool for all cores
#SBATCH -t 6-12:00 # time (D-HH:MM)

singularity exec ../rstan_latest.sif Rscript --vanilla analysis/03-hosp_run_m3.R