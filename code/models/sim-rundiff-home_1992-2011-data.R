#!/usr/bin/env Rscript

nu <- 10
sigma_y <- 4
b_home <- 0.4

dat <- list()
dat$n_games <- 46510
dat$rundiff <- b_home + rt(dat$n_games, nu) * sigma_y

rstan::stan_rdump(names(dat), envir = list2env(dat),
                  file = "../../outputs/models/rundiff-home_1992-2011-sim.data.R")
