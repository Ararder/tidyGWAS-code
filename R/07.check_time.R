library(fs)
library(stringr)
library(purrr)
library(dplyr)
library(ggplot2)
library(lubridate)
library(tidyr)
library(patchwork)

jobs <- dir_ls("slurm", glob = "*tidy-small*") |> 
    path_file() |> 
    str_extract("[0-9]{1,12}_[0-9]{1}")

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



names <- c("tidy-small", "tidy-big", "mss-small", "mss-big")
data <- map(names, make_df) |> 
    list_rbind() |> 
    separate(type, into = c("method", "sumstat"), sep = "-")
d <- data


data <- 
    d |> 
    mutate(sumstat = if_else(sumstat == "small", "9 million rows", "40 million rows")) |> 
    mutate(method = if_else(method == "tidy", "tidyGWAS", "MungeSumstats"))




# httpgd::hgd()


data |> 
    ggplot(aes(sumstat, time, color = method)) +
    geom_point() +
    coord_flip() +
    scale_y_time() +
    theme_light() 


data |> 
ggplot(aes(type, mem, color = type)) +
geom_point() +
coord_flip() +
theme_light() +
labs(
    y = "Memory Utilized (GB)"
)

labs <- 
data |> 
    mutate(grp = paste(method, sumstat)) |> 
    group_by(grp) |> 
    summarise(
        mean_mem = mean(mem),
        mean_time = mean(seconds(time))
    )


time_fig <- data |> 
    mutate(grp = paste(method, sumstat, " - ")) |> 
    ggplot(aes(time, grp, color = method)) + 
    geom_boxplot() +
    geom_point(alpha = 0.7, aes(color = method)) +
    scale_x_time() +
    theme_light() +
    labs(
        x = "Wall-clock time",
        y = " ",
        color = " "
    ) +
    theme(legend.position = c(0.90, 0.90))


mem_fig <- data |> 
    mutate(grp = paste(method, sumstat, " - ")) |> 
    ggplot(aes(mem, grp, color = method)) + 
    geom_boxplot() +
    geom_point(alpha = 0.7, aes(color = method)) +
    theme_light() +
    labs(
        x = "Memory Utilized (GB)",
        y = " ",
        color = " "
    )


# remove the legend
mem_fig <- mem_fig +
    theme(legend.position = "none") +
    # remove y-axis
    theme(axis.text.y = element_blank())

time_fig + mem_fig

final_fig <- (time_fig + mem_fig) + plot_layout(guides = "collect")
ggsave("figures")