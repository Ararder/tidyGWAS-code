library(downstreamGWAS)
library(fs)
library(dplyr)
library(purrr)
library(tidyr)
library(stringr)
library(ggplot2)
library(forcats)
library(lubridate)
library(patchwork)

all <- dir_ls("/cfs/klemming/projects/supr/ki-pgi-storage/Data/sumstats/wave1")
all2 <- dir_ls("/cfs/klemming/projects/supr/ki-pgi-storage/Data/sumstats/wave2")


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
readr::write_tsv(merged, "workflow/row_removs.tsv")



# suic thoughts --------------------------------------------------------------
# MY guess is they inner_joined on refsnp table: get two matches then?
# tbl_kept <- arrow::read_parquet('/work/users/a/r/arvhar/tidyGWAS_stuff/output2/suicidal_thoughts/raw/raw.parquet')
# tbl <- arrow::read_parquet('/work/users/a/r/arvhar/tidyGWAS_stuff/output2/suicidal_thoughts/pipeline_info/removed_duplicates.parquet')

# tbl_kept |> 
#   filter(CHR == 3 & POS == 4234973 & EffectAllele == "CT" & OtherAllele == "C")




# figures -----------------------------------------------------------------
# tbl <- arrow::read_parquet('/work/users/a/r/arvhar/tidyGWAS_stuff/output2/type_1_diabetes/pipeline_info/removed_validate_chr_pos_path.parquet')




# remove some outliers
# -------------------------------------------------------------------------
# httpgd::hgd()
