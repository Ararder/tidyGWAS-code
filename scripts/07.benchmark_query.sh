#!/bin/sh
#SBATCH --account=naiss2024-5-201
#SBATCH --partition=main
#SBATCH --array=1-10
#SBATCH --output=slurm/query-region%A_%a.out
#SBATCH --time=00:10:00
ml PDC/23.12 R/4.4.0

Rscript R/03.query_region.R