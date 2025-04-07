library(tidyverse)
library(arrow)
library(fs)
library(glue)
library(downstreamGWAS)

# transform to metal format
to_metal <- function(path) {
    name <- path |> 
    stringr::str_extract("dataset_name=(.*)") |> 
    stringr::str_remove("dataset_name=") 

    arrow::open_dataset(path) |> 
        dplyr::select(
            any_of(c(
                "RSID",
        "EffectAllele",
        "OtherAllele",
        "B",
        "P",
        "SE",
        "EAF",
        "N",
        "INFO"
    ))) |> 
    dplyr::collect() |> 
    readr::write_tsv(paste0("workflow/metal_benchmark/", name, ".tsv"))

}

purrr::walk(fs::dir_ls(p), \(x) {
    to_metal(x)
    gc()
    }, .progress = list(type = "tasks"))









# prepare metal code
sumstats <- dir_ls("workflow/metal_benchmark", glob = "*.tsv")
header <- c("SCHEME STDERR",
"MARKER RSID",
"ALLELE EffectAllele OtherAllele",
"EFFECT B",
"PVALUE P",
"STDERR SE",
"CUSTOMVARIABLE N",
"LABEL N as N",
"\n")

middle <- paste0("PROCESS ", sumstats)

end <- c(
"OUTFILE workdir/metal_benchmark/file_ .tbl",
"ANALYZE"
)

c(header, middle, end) |> 
writeLines("scripts/run_metal.metal")





