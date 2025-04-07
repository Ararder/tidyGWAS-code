#!/bin/bash
#SBATCH --account=naiss2024-5-201
#SBATCH --partition=main
#SBATCH --array=1-10
#SBATCH --mem=70gb
#SBATCH --output=slurm/meta-analysis-%A_%a.out
#SBATCH --time=24:00:00
ml PDC/23.12 R/4.4.0

Rscript -e "library(arrow)" -e "s <- arrow::schema(POS_38 = int32(),POS_37 = int32(),RSID = string(),EffectAllele = string(),OtherAllele = string(),B = double(),P = double(),EAF = double(),Z = double(),SE = double(),N = int32(),indel = bool(),rowid = int32(),multi_allelic = bool(),REF_37 = string(),REF_38 = string(),CHR = string(),dataset_name = string())" -e "ds <- arrow::open_dataset('workflow/PGC3', schema = s)" -e "res <- tidyGWAS::meta_analyze(ds |> dplyr::rename(POS = POS_37, REF = REF_37))"