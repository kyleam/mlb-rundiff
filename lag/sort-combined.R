#!/usr/bin/Rscript

library(dplyr)
library(lubridate)
library(readr)

read_csv("lag-combined-1990_2016.csv") %>%
    mutate(date = ymd(date)) %>%
    arrange(date, matchup, team, dbl_header) %>%
    write_csv("lag-combined-sorted-1990_2016.csv")
