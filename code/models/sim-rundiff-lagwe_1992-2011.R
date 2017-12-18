#!/usr/bin/env Rscript

library(rstan)

source("sim-rundiff-lagwe.R")

set.seed(727308)

fit <- readRDS("../../outputs/models/rundiff-lagwe_1992-2011-fit.rds")
dat <- read_rdump("../../outputs/models/rundiff-lagwe_1992-2011.data.R")
samps <- extract(fit)

sim <- sim_rundiffs(dat, samps)

saveRDS(sim, "../../outputs/models/rundiff-lagwe_1992-2011-sim.rds")
