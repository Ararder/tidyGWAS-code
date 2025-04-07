#!/bin/bash
#!/bin/bash
#SBATCH --account=naiss2024-5-201
#SBATCH --partition=main
#SBATCH --array=1-10
#SBATCH --mem=70gb
#SBATCH --output=slurm/tidy-small-%A_%a.out
#SBATCH --time=24:00:00
ml PDC/23.12 R/4.4.0

Rscript -e "tidyGWAS::tidyGWAS(
        tbl = 'workflow/raw_data/pgc3_scz.tsv', 
        delim = '\t',
        dbsnp_path = '/cfs/klemming/projects/supr/ki-pgi-storage/Data/downstreamGWAS/reference/dbSNP155',
        column_names = list(
            CHR = 'CHROM', 
            RSID = 'ID', 
            EffectAllele = 'A1', 
            OtherAllele = 'A2', 
            EAF = 'FCAS', 
            INFO = 'IMPINFO',
            B = 'BETA',
            P = 'PVAL', 
            CaseN = 'NCAS', 
            ControlN = 'NCON'
        ),
        output_format = 'hivestyle')"