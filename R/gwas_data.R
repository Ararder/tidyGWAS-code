library(googlesheets4)
library(tidyverse)



url <- "https://docs.google.com/spreadsheets/d/1SAc4SsRM8OIHJxoTt8QiIxpGwLGccPub2kMGBVfHu6M/edit?gid=1516885611#gid=1516885611"

df <- read_sheet(url, sheet = "joelle_metadata")


sub_df <- df |> 
  select(phenotype, dataset_name, pmid)

ll <- readLines("scripts/run_metal.metal")
traits_used <- ll[11:86] |> 
  str_remove("PROCESS workflow/metal_benchmark/") |> 
  str_remove(".tsv") |> 
  tibble(dataset_name = _)


left_join(traits_used, sub_df) |> 
  write_tsv("data/table_s2.tsv")

# -------------------------------------------------------------------------


qc <- read_tsv("data/row_removs.tsv")

xx <- read_sheet(url, sheet = "final_metadata")


all_sumstats <- inner_join(qc, xx, by = "dataset_name") |> 
  select(dataset_name, phenotype, pmid) |> 
  filter(!dataset_name %in% known_err) |> 
  mutate(pmid = as.character(pmid))


view(all_sumstats)
