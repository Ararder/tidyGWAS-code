library(dplyr)
library(fs)
library(readr)



ds <- arrow::open_dataset("/cfs/klemming/home/a/arvhar/ki-pgi-storage/Data/downstreamGWAS/reference/dbSNP155/EAF_REF_1KG")

EAF_file <- ds |> 
    filter(ancestry == "EUR") |> 
    dplyr::collect()



dir_ls(glob ="*txt")


df <- read_tsv(dir_ls(glob ="*txt"))
    "AF_POP_1kGP_high_coverage_Illumina.chr21.filtered0.001.txt")


vals <- df |> 
    select(CHROM, POS, REF, ALT, contains("unrel")) |> 
    tidyr::pivot_longer(-c("CHROM", "POS", "REF", "ALT"), names_to = "ancestry", values_to = "AF")



paths <- dir_ls("workflow/AF_ref/", glob ="*txt")

process_allele_freq <- function(path, outpath) {

df <- read_tsv(path)
 vals <- df |> 
    select(CHROM, POS, REF, ALT, contains("unrel")) |> 
    tidyr::pivot_longer(-c("CHROM", "POS", "REF", "ALT"), names_to = "ancestry", values_to = "AF") |> 
    filter(AF > 0) |> 
    mutate(CHROM = stringr::str_remove(CHROM, "chr")) |> 
    mutate(ancestry = stringr::str_remove(ancestry,"AF_") |> stringr::str_remove("_unrel")) |> 
    rename(CHR = CHROM, EffectAllele = ALT, OtherAllele = REF, EAF = AF)

    arrow::write_dataset(dplyr::group_by(vals, ancestry, CHR), outpath)

}

purrr::walk(paths[3:23], process_allele_freq, outpath = "EAF_REF_1KG")

x <- arrow::open_dataset("EAF_REF_1KG/ancestry=AFR")
convert_to_one <- function(ancestry) {
    
    ds <- arrow::open_dataset(paste0("EAF_REF_1KG/ancestry=", ancestry)) |> 
        dplyr::collect()
    out <- glue::glue("/cfs/klemming/home/a/arvhar/ki-pgi-storage/Data/downstreamGWAS/reference/dbSNP155/EAF_REF_1KG/ancestry={ancestry}/part-0.parquet")
    dir_create(path_dir(out))
    arrow::write_parquet(ds, out)
        



}
purrr::walk(
    c("AFR", "AMR", "EAS", "SAS"),
    convert_to_one
    )
