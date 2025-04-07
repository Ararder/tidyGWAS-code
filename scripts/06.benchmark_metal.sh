#!/bin/bash
#SBATCH --account=naiss2024-5-201
#SBATCH --partition=main
#SBATCH --array=3-10
#SBATCH --mem=70gb
#SBATCH --output=slurm/metal-meta-%A_%a.out
#SBATCH --time=24:00:00
ml PDC/23.12 R/4.4.0




workflow/generic-metal/metal scripts/run_metal.metal