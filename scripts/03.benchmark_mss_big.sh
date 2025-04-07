#!/bin/bash
#SBATCH --account=naiss2024-5-201
#SBATCH --partition=main
#SBATCH --array=1-10
#SBATCH --mem=70gb
#SBATCH --output=slurm/mss-big-%A_%a.out
#SBATCH --time=24:00:00
ml PDC/23.12 R/4.4.0


Rscript -e "MungeSumstats::format_sumstats(
    path = 'workflow/raw_data/eo.assoc.gz',
    ref_genome='GRCh37', 
    log_folder_ind=TRUE, 
    nThread = 8, 
    imputation_ind=TRUE)"
