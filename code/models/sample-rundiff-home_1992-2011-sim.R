
library(rstan)

rstan_options(auto_write = TRUE)
options(mc.cores = 2)

data <- read_rdump("../../outputs/models/rundiff-home_1992-2011-sim.data.R")

fit <- stan("rundiff-home.stan", data = data,
            iter = 1000, chains = 4,
            seed = 404879)

saveRDS(fit, "../../outputs/models/rundiff-home_1992-2011-sim-fit.rds")
