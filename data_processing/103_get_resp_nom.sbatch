#!/bin/bash
#
#SBATCH -p serial_requeue # partition (queue)
#SBATCH -c 4 # number of cores
#SBATCH --mem 36GB # memory pool for all cores
#SBATCH -t 0-00:10 # time (D-HH:MM)
#SBATCH --array=2000-2018

python data_processing/103_get_resp_nom.py --year $SLURM_ARRAY_TASK_ID