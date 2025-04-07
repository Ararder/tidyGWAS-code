library(downstreamGWAS)
library(fs)
library(tidyverse)
library(lubridate)
library(patchwork)
source("R/functions.R")

all <- dir_ls("/cfs/klemming/projects/supr/ki-pgi-storage/Data/sumstats-repo/workflow/wave1")
all2 <- dir_ls("/cfs/klemming/projects/supr/ki-pgi-storage/Data/sumstats-repo/workflow/wave2")


known_err <- c("cancerpanc", "pulsepress", "systolpress", "scz2011", "mdd2013", "diabloodpres", "parkinson2019", 
               "atrialfib")

duplications <- c("t1d", "t2d", "alzheimer", "als", "anorexia_nervosa_PGC2","autism", "cancerbreast", "smokingces", "smokingever")


parent_dir <- all[1]

parse_removed_rows <- function(parent_dir) {
  all_df <- fs::dir_ls(fs::path(parent_dir, "pipeline_info/"), glob = "*removed*") |> 
    purrr::map(arrow::read_parquet)
  
    col_validator <- paste0(parent_dir, "/pipeline_info/removed_validate_chr_pos_path.parquet")
    # calculate n missing per column validation, remove rowid
    
    # reason2 <- 
      # all_df[which(!names(all_df) == col_validator)] |> 
      all_df |>
      map(\(x) dplyr::select(x, "rowid")) |> 
      purrr::list_rbind(names_to = "reason") |> 
      dplyr::mutate(
        reason = fs::path_file(reason),
        reason = str_remove(reason, "removed_"),
        reason = str_remove(reason, ".parquet")
      ) |> 
      count(reason) |> 
      pivot_wider(names_from = "reason", values_from = "n") |> 
      mutate(
        dataset_name = path_file(parent_dir)
      ) |> 
      select(dataset_name, everything())
    

}

x <- map(all, parse_removed_rows) |> 
  list_rbind() |> 
  janitor::clean_names() |> 
  mutate(across(everything(), \(x) replace_na(x, replace = 0)))


y <- map(all2, parse_removed_rows) |> 
  list_rbind() |> 
  janitor::clean_names() |> 
  mutate(across(everything(), \(x) replace_na(x, replace = 0)))




merged <- bind_rows(x,y)
readr::write_tsv(merged, "data/row_removs.tsv")



####


names <- c("tidy-small", "tidy-big", "mss-small", "mss-big")
data <- map(names, make_df) |> 
    list_rbind() |> 
    separate(type, into = c("method", "sumstat"), sep = "-")
d <- data



data <- 
    d |> 
    mutate(sumstat = if_else(sumstat == "small", "7.5 million rows", "40 million rows")) |> 
    mutate(method = if_else(method == "tidy", "tidyGWAS", "MungeSumstats"))

# save for posterity
write_rds(data, "data/benchmark.rds")



#


# Code to get time and memory usage from slurm jobs
meta_bench <- make_df("tidy-meta") |> mutate(method = "tidyGWAS")
meta_bench_metal <- make_df("metal-meta") |> mutate(method = "metal")
all <- bind_rows(meta_bench, meta_bench_metal)
write_rds(all, "data/meta_benchmark.rds")