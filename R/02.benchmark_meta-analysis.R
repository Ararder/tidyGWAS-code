library(dplyr)
library(arrow)
library(fs)
library(glue)
library(downstreamGWAS)




create_lake <- function(dir, lake) {
  paths <- fs::dir_ls(dir, type = "dir", glob = "*tidyGWAS_hivestyle", recurse = 1)
  fs::dir_create(lake)
  
  tbl <- dplyr::tibble(
    tdg_path = paths,
    name = path_dir(tdg_path) |> path_file(),
    new_path = path(lake, glue::glue("dataset_name={name}"))
  )
  
  fs::link_create(tbl$tdg_path, tbl$new_path)
  
}

create_lake(
  "/cfs/klemming/projects/supr/ki-pgi-storage/Data/sumstats-repo/workflow/wave1",
  "/cfs/klemming/projects/supr/ki-pgi-storage/Data/sumstats-repo/workflow/arrow_wave1"
)

create_lake(
  "/cfs/klemming/projects/supr/ki-pgi-storage/Data/sumstats-repo/workflow/wave2",
  "/cfs/klemming/projects/supr/ki-pgi-storage/Data/sumstats-repo/workflow/arrow_wave2"
)


# figure out why time differs

dset1  <-  arrow::open_dataset("/cfs/klemming/projects/supr/ki-pgi-storage/Data/sumstats-repo/workflow/arrow_wave1")
dset2  <-  arrow::open_dataset("/cfs/klemming/projects/supr/ki-pgi-storage/Data/sumstats-repo/workflow/arrow_wave2")


s <- arrow::schema(
  POS_38 = int32(),
  POS_37 = int32(),
  RSID = string(),
  EffectAllele = string(),
  OtherAllele = string(),
  B = double(),
  P = double(),
  EAF = double(),
  Z = double(),
  SE = double(),
  N = int32(),
  indel = bool(),
  rowid = int32(),
  multi_allelic = bool(),
  REF_37 = string(),
  REF_38 = string(),
  CHR = string(),
  dataset_name = string()
)

merged_dset <- arrow::open_dataset(list(dset1, dset2), schema = s) 





# 0.7 seconds
# first query differs from second?
query_region <- function() {
  all_sig <- merged_dset |> 
    dplyr::filter(P < 5e-08) |> 
    dplyr::filter(CHR == "7") |> 
    dplyr::filter(POS_38 >= 1788081 & POS_38 <= 2289862) |> 
    dplyr::select(RSID, P, B, SE, dataset_name) |> 
    dplyr::collect() |> 
    dplyr::group_by(dataset_name) |> 
    dplyr::slice_min(P)
}


results <- microbenchmark::microbenchmark(
  query_region(),
  times = 10L
)



query_all_snps <- function() {
  merged_dset |> 
    dplyr::select(RSID, P,dataset_name) |> 
    dplyr::filter(P < 5e-08) |> 
    dplyr::collect()

}

results <- microbenchmark::microbenchmark(
  query_all_snps(),
  times = 1L
)


create_lake(
  "/cfs/klemming/home/a/arvhar/ki-pgi-storage/Data/sumstats/PGC3_updated",
  "workflow/PGC3"
)

s <- arrow::schema(
  POS_38 = int32(),
  POS_37 = int32(),
  RSID = string(),
  EffectAllele = string(),
  OtherAllele = string(),
  B = double(),
  P = double(),
  EAF = double(),
  Z = double(),
  SE = double(),
  N = int32(),
  indel = bool(),
  rowid = int32(),
  multi_allelic = bool(),
  REF_37 = string(),
  REF_38 = string(),
  CHR = string(),
  dataset_name = string()
)

ds <- arrow::open_dataset("workflow/PGC3", schema = s)




tictoc::tic("meta-analyse 188 traits")
res <- tidyGWAS::meta_analyze(ds |> rename(POS = POS_37, REF = REF_37))
tictoc::toc()

length(dir_ls("/cfs/klemming/projects/supr/ki-pgi-storage/Data/sumstats/arrow_wave1")) +
length(dir_ls("/cfs/klemming/projects/supr/ki-pgi-storage/Data/sumstats/arrow_wave2"))
# meta-analysis of 128 traits

tictoc::tic("meta-analyse 188 traits")
res <- tidyGWAS::meta_analyze(dset1 |> rename(POS = POS_37, REF = REF_37))
tictoc::toc()





# FIGURE OUT WHICH SUMSTATS have the wrong column type
paths <- dir_ls("/cfs/klemming/projects/supr/ki-pgi-storage/Data/sumstats/arrow/wave2")
path <- paths[1]
library(purrr)
library(dplyr)
get_col_types <- function(path) {
  dset <- open_dataset(path)
  schema <- dset$schema

  cols <- colnames(dset)

  map(cols, \(y) {
    ll <-  schema[[y]]$ToString()
    ll <- stringr::str_split_1(ll, ": ") 
    dplyr::tibble(col = ll[1], type = ll[[2]])

  }) |> 
  list_rbind() |> 
  tidyr::pivot_wider(names_from = col, values_from = type) |> 
  mutate(dataset_name = fs::path_file(path)) |> 
  relocate(dataset_name)

}

all <- map(paths, get_col_types) |> 
  list_rbind()

all |> 
filter(CaseN == "double") |> 
select(dataset_name)
