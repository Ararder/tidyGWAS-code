library(downstreamGWAS)
library(fs)
library(tidyverse)
library(lubridate)
library(patchwork)



merged <- read_tsv("data/row_removs.tsv")
  



pdf <- 
 merged |> 
  janitor::clean_names() |> 
  mutate(across(everything(), \(x) replace_na(x, replace = 0))) |> 
  pivot_longer(-1) |> 
  mutate(name = case_when(
  name == "validate_chr_pos_path_parquet" ~ "Validation of statistics columns",
  name == "validate_indels_parquet" ~ "Validation of indels",
  name == "missing_critical" ~ "Missing in variant ID column (RSID or CHR:POS)", 
  name == "duplications_chr_pos_in_rsid_col" ~ "duplications between RSID and CHR:POS",
  .default = name),
  name = stringr::str_to_sentence(name) 
  )
  

switch <- c("Duplicates" = "Duplicated rows",
"Duplications between rsid and chr:pos" = "Duplications between RSID and CHR:POS",
"Invalid_rsid" = "Invalid RSID",
"Missing in variant id column (rsid or chr:pos)" = "Missing in variant ID column (RSID or CHR:POS)",
"Missing_alleles"  = "Missing alleles",
"Nodbsnp" = "Not in dbSNP",
"Validation of indels" = "Validation of indels",
"Validation of statistics columns" = "Validation of statistics columns"
)

# use the swich vector to rename the name column
pdf <- pdf |> 
  mutate(name = case_when(
    name %in% names(switch) ~ switch[name],
    TRUE ~ name
  ))

pdf |> 
  filter(value > 0) |> 
  count(name)
  
  





labdf <- pdf |> 
  group_by(name) |> 
  summarise(
    mean = mean(value),
    median = median(value),
    max = max(value),
    min = min(value),
    n_nonzero = sum(value > 0)
    ) |> 
    mutate(
      lab_mean = paste0("Mean: ", scales::comma(mean)),
      lab_median = paste0("Median: ", scales::comma(median)),
      lab_nnz = paste0("N Non-zero: ", scales::comma(n_nonzero))
      )
           
# httpgd::hgd()
s <- 3
fig1 <- pdf |> 
  filter(value > 0)  |> 
  ggplot(aes(name, value, color = name)) +
  geom_boxplot() +
  coord_flip() +
  theme_light() +
  theme(
    axis.text=element_text(size=12),
    axis.title=element_text(size=14)
  ) +  
  geom_text(data = mutate(labdf, value = 500000), aes(label = lab_mean), hjust=0, size = s) +
  geom_text(data = mutate(labdf, value = 500000), aes(label = lab_nnz), color = "black", nudge_x = +0.15,hjust=0, size = s) +
  geom_text(data = mutate(labdf, value = 500000), aes(label = lab_median), color = "black", nudge_x = -0.15,hjust=0, size = s) +
  labs(
    x = " ",
    y = "# of rows removed",
    color = " ") +
    ggtitle("A") +
    #remove legend
    theme(legend.position = "none")
fig1








########## 
##  Now benchmarking and memory usage

data <- read_rds("data/benchmark.rds")




labs <- 
    data |> 
    mutate(grp = paste(method, sumstat)) |> 
    group_by(grp) |> 
    summarise(
        mean_mem = mean(mem),
        mean_time = mean(seconds(time)),
    )


time_fig <- data |> 
    mutate(grp = paste(method, sumstat, " - ")) |> 
    ggplot(aes(time, grp, color = method)) + 
    geom_boxplot() +
    geom_point(alpha = 0.7, aes(color = method)) +
    scale_x_time() +
    theme_light() +
    theme(
    axis.text=element_text(size=12),
    axis.title=element_text(size=14)
    ) +  
    labs(
        x = "Wall-clock time",
        y = " ",
        color = " "
    ) +
    theme(legend.position = c(0.75, 0.85)) +
    ggtitle("B")


mem_fig <- data |> 
    mutate(grp = paste(method, sumstat, " - ")) |> 
    ggplot(aes(mem, grp, color = method)) + 
    geom_boxplot() +
    geom_point(alpha = 0.7, aes(color = method)) +
    theme_light() +
    theme(
    axis.text=element_text(size=12),
    axis.title=element_text(size=14)
    ) +  
    labs(
        x = "Memory Utilized (GB)",
        y = " ",
        color = " "
    ) +
    ggtitle("C")


# remove the legend
mem_fig <- mem_fig +
    theme(legend.position = "none") +
    # remove y-axis
    theme(axis.text.y = element_blank())





# calculate the mean time and memory usage for in-text reference


text_ref <- 
data |> 
    mutate(grp = paste(method, sumstat)) |> 
    group_by(grp) |> 
    summarise(
        mean_mem = mean(mem),
        sd_mem = sd(mem),
        mean_time = mean(seconds(time) / 60),
        sd_time = sd(seconds(time) / 60),
        
        iqr  =IQR(seconds(time) / 60)
    )


text_ref



# Meta-analysis results ---------------------------------------------------


meta_bench <- 
  read_rds("data/meta_benchmark.rds") |>
  mutate(mem = as.numeric(mem)) |> 
  mutate(method = if_else(method == "metal", "Metal", method))


time <- meta_bench |> 
  ggplot(aes(time, method, color = method)) + 
  geom_boxplot() +
  geom_point(alpha = 0.7, aes(color = method)) +
  scale_x_time() +
  theme_light() +
  theme(
    axis.text=element_text(size=12),
    axis.title=element_text(size=14)
  ) +  
  labs(
    x = "Wall-clock time",
    y = " ",
    color = " "
  ) +
  theme(
    legend.position = c(0.75, 0.85),
    # tilt the x-axis labels
    axis.text.x = element_text(angle = 15, hjust = 1),
    ) +
  ggtitle("D")


mem <- 
  meta_bench |> 
  ggplot(aes(mem, method, color = method)) + 
  geom_boxplot() +
  theme_light() +
  theme(
    axis.text=element_text(size=12),
    axis.title=element_text(size=14)
  ) +  
  labs(
    x = "Memory Utilized (GB)",
    y = " ",
    color = " "
  ) +
  ggtitle("E")



final_fig <- fig1 / (time_fig + mem_fig) / (time + mem)
ggsave("figures/figure1.png", final_fig, dpi = 350, height = 16, width = 14)






meta_bench |>
  group_by(method) |> 
  summarise(
      mean_time = mean(seconds(time) / 60),
      sd_time = sd(seconds(time) / 60),
      iqr = IQR(seconds(time) / 60),
      mean_mem = mean(mem),
  )
