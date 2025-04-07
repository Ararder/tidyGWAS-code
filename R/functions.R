
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



