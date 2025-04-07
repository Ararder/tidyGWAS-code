library(fs)
library(arrow)
library(stringr)
library(dplyr)
library(purrr)
library(lubridate)






# to_metal <- function(path) {
#     name <- path |> 
#     stringr::str_extract("dataset_name=(.*)") |> 
#     stringr::str_remove("dataset_name=") 

#     arrow::open_dataset(path) |> 
#         dplyr::select(RSID,
#         EffectAllele,
#         OtherAllele,
#         B,
#         P,
#         SE,
#         EAF,
#         N,
#         INFO
#     ) |> 
#     dplyr::collect() |> 
#     readr::write_tsv(paste0("workflow/metal_benchmark/", name, ".tsv"))

# }

# purrr::walk(fs::dir_ls("workflow/PGC3"), to_metal)






get_ids <- function(x) {
    glob <- paste0("*", x, "*")
    dir_ls("slurm", glob = glob) |> 
    path_file() |> 
    str_extract("[0-9]{1,12}_[0-9]{1,2}")

}

make_df <- function(y) {

    ids <- get_ids(y)

    x <- map(ids, \(x) system(paste0("seff ", x), intern = TRUE))

    purrr::map(x, \(x) {
        mem <-  x[[11]] |> 
            str_remove("Memory Utilized: ") |> 
            str_remove(" GB")  |> 
            str_remove(" MB")
            as.numeric()

        time <-  
            x[[10]] |> 
            str_remove("Job Wall-clock time: ") |> 
            hms()
        array_job <- x[[2]] |> 
            str_remove("Array Job ID: ")
        
        dplyr::tibble(
            type = y,
            mem = mem,
            time = time,
            array_job = array_job
        )
    }) |> 
    purrr::list_rbind()
}   

results <- make_df("metal")

results |> 
summarise(
    time = mean(seconds(time)/60),
    mem = mean(mem)
)


# check for query
results <- make_df("query-region")
get_ids("query-region") 
results |> 
    summarise(
        time = mean(seconds(time)),
        mem = mean(as.numeric(mem))
    )


results <- microbenchmark::microbenchmark(
  source("R/03.query_region.R"),
  times = 10L
)

tictoc::tic()
source("R/03.query_region.R")
tictoc::toc()