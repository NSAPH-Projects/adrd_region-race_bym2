#!/bin/bash
#
#SBATCH -p fasse # partition (queue)
#SBATCH -c 4 # number of cores
#SBATCH --mem 24GB # memory pool for all cores
#SBATCH -t 0-00:10 # time (D-HH:MM)

python data_processing/201_adm_county.py $SLURM_ARRAY_TASK_ID