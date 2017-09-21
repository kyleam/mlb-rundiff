#!/usr/bin/Rscript

library(dplyr)

glog <- readr::read_csv("../lag/log-with-lags-cleaned.csv") %>%
    mutate(yr = lubridate::year(date))

dat <- glog %>%
    filter(between(yr, 1992, 2011)) %>%
    transmute(rundiff = home_runs_scored - away_runs_scored) %>%
    as.list()
dat$n_games <- length(dat$rundiff)

rstan::stan_rdump(names(dat), envir = list2env(dat),
                  file = "rundiff-home_1992-2011.data.R")
