library(arrow)

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
dset1  <-  arrow::open_dataset("/cfs/klemming/projects/supr/ki-pgi-storage/Data/sumstats/arrow_wave1", schema = s)
dset2  <-  arrow::open_dataset("/cfs/klemming/projects/supr/ki-pgi-storage/Data/sumstats/arrow_wave2", schema = s)



merged_dset <- arrow::open_dataset(list(dset1, dset2)) 

all_sig <- merged_dset |> 
    dplyr::filter(P < 5e-08) |> 
    dplyr::filter(CHR == "7") |> 
    dplyr::filter(POS_38 >= 1788081 & POS_38 <= 2289862) |> 
    dplyr::select(RSID, P, B, SE, dataset_name) |> 
    dplyr::collect() |> 
    dplyr::group_by(dataset_name) |> 
    dplyr::slice_min(P)
