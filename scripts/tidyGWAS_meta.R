library(arrow) 
s <- arrow::schema(POS_38 = int32(),POS_37 = int32(),RSID = string(),EffectAllele = string(),OtherAllele = string(),B = double(),P = double(),EAF = double(),Z = double(),SE = double(),N = int32(),indel = bool(),rowid = int32(),multi_allelic = bool(),REF_37 = string(),REF_38 = string(),CHR = string(),dataset_name = string())
ds <- arrow::open_dataset("/cfs/klemming/home/a/arvhar/ki-pgi-storage/Data/sumstats-repo/workflow/arrow_wave2", schema = s) 


res <- tidyGWAS::meta_analyze(ds, by = c("CHR", "POS_37", "RSID", "EffectAllele", "OtherAllele", "OtherAllele"), ref = "REF_37")