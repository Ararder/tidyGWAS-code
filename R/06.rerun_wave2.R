library(tidyGWAS)
library(arrow)
library(readr)
library(fs)
library(dplyr)



snp_cols <- c("CHR", "POS", "RSID", "EffectAllele", "OtherAllele", "rowid")
info_cols <- c("INFO", "N", "CaseN", "ControlN","EffectiveN", "EAF")
stats_cols <- c("B", "Z", "OR", "P", "SE", info_cols)
valid_column_names <- c(snp_cols, stats_cols, info_cols)
dbsnp_path <- "/cfs/klemming/projects/supr/ki-pgi-storage/Data/downstreamGWAS/reference/dbSNP155"

raw_path <- fs::dir_ls("/cfs/klemming/projects/supr/ki-pgi-storage/Data/sumstats/PGC3_MDD/", recurse = TRUE, glob = "*/raw/*")
param_df_full <- tibble(
    raw_path = raw_path,
    basepath = path_dir(path_dir(raw_path)),
    name = path_file(basepath)
    )


rerun_tidygwas <- function(param_df) {
    stopifnot(all(c("raw_path", "basepath", "name") %in% colnames(param_df)))
    stopifnot(nrow(param_df) == 1)
    p_m <- path(param_df$basepath, "metadata.yaml")
    metadata <- yaml::read_yaml(p_m)
    raw <- arrow::read_parquet(param_df$raw_path)
    column_names <- metadata[names(metadata) %in% valid_column_names]
    output_dir <- path("/cfs/klemming/projects/supr/ki-pgi-storage/Data/sumstats/PGC3_updated", param_df$name)



    tidyGWAS(
        tbl = raw,
        dbsnp_path,
        column_names = column_names,
        logfile=TRUE,
        output_dir = output_dir
    )



}


arg <- as.numeric(commandArgs(trailingOnly=TRUE))
tmp <- split(param_df_full, f = rep(1:4, length.out = nrow(param_df_full)))
to_run <- tmp[[arg]]$name

cli::cli_alert("Running chunk {arg}: {to_run}")
purrr::map(
    to_run, \(x) {
    params <- dplyr::filter(param_df_full, name == {{ x }}) 
    rerun_tidygwas(params)
    gc()
    }
)