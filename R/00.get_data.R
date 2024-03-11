library(tidyverse)
library(downstreamGWAS)
library(tidyGWAS)
library(fs)



all <- dir_ls("/work/users/a/r/arvhar/tidyGWAS_stuff/output2/")
all2 <- dir_ls("/work/users/a/r/arvhar/tidyGWAS_stuff/output1/")


known_err <- c("cancerpanc", "pulsepress", "systolpress", "scz2011", "mdd2013", "diabloodpres", "parkinson2019", 
               "atrialfib")

duplications <- c("t1d", "t2d", "alzheimer", "als", "anorexia_nervosa_PGC2","autism", "cancerbreast", "smokingces", "smokingever")


# tibble(path = all) |> 
#   bind_rows(tibble(path=all2)) |> 
#   mutate(
#     dataset_name = path_file(path)
#   ) |> 
#   relocate(dataset_name) |> 
#   filter(!dataset_name %in% known_err) |> 
#   view()





parse_removed_rows <- function(parent_dir) {
  all_df <- fs::dir_ls(fs::path(parent_dir, "pipeline_info/"), glob = "*removed*") |> 
    purrr::map(arrow::read_parquet)
  
    col_validator <- paste0(parent_dir, "/pipeline_info/removed_validate_chr_pos_path.parquet")
    # calculate n missing per column validation, remove rowid
    if(!is_empty(which(names(all_df) == col_validator))) {
      
      reason1 <- all_df[[which(names(all_df) == col_validator)]][,-1] |> 
        map(sum) |>
        as_tibble()
    } else {
      reason1 <- tibble()
    }
      
  
    
    reason2 <- 
      all_df[which(!names(all_df) == col_validator)] |> 
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
    
    bind_cols(reason2, reason1)
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
# Investigate parkinson: ~2mil rows were incorrectly meta-analyzed
# with one cohort supplying chr:pos, and one cohort supplying RSID
# -------------------------------------------------------------------------
  
  
  
  
  

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
known_err <- c("cancerpanc", "pulsepress", "systolpress", "scz2011", "mdd2013", "diabloodpres", "parkinson2019", "atrialfib")



pdf <- merged |> 
  filter(!dataset_name %in% known_err) |> 
  janitor::clean_names() |> 
  mutate(across(everything(), \(x) replace_na(x, replace = 0)))
  


# figures ----------------------------------------------------------------


fig1 <- pdf |> 
  pivot_longer(-1) |> 
  group_by(name) |> 
  summarise(value = sum(value)) |> 
  mutate(name = if_else(name == "validate_chr_pos_path", "Validation of statistics columns", name)) |> 
  mutate(name = fct_reorder(name, value)) |> 
  ggplot(aes(name, log10(value))) +
  geom_col() +
  coord_flip() +
  theme_classic() +
  scale_y_continuous(labels = scales::comma_format()) +
  labs(
    title = "Total number of rows removed across 243 summary statistics",
    y = "# rows removed (log10 transformed)",
    x = "Reason for removal"
  )


fig2 <- pdf |> 
  pivot_longer(-1) |> 
  ggplot(aes(log10(value+1))) +
  geom_density() +
  facet_wrap(~name) +
  theme_light()



