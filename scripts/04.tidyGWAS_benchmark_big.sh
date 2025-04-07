#!/bin/bash
#SBATCH --account=naiss2024-5-201
#SBATCH --partition=main
#SBATCH --array=1-10
#SBATCH --mem=70gb
#SBATCH --output=slurm/tidy-big-%A_%a.out
#SBATCH --time=24:00:00
ml PDC/23.12 R/4.4.0

Rscript -e "tidyGWAS::tidyGWAS(
        tbl = 'workflow/raw_data/eo.assoc.gz', 
        delim = '\t',
        dbsnp_path = '/cfs/klemming/projects/supr/ki-pgi-storage/Data/downstreamGWAS/reference/dbSNP155',
        column_names = list(
            POS = 'BP', 
            RSID = 'ID',
            EffectAllele = 'ALT', 
            OtherAllele = 'REF', 
            B = 'EFFECT', 
            EAF = 'ALT_FREQ'
        ))"