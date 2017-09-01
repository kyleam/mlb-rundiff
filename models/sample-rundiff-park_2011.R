
library(rstan)

rstan_options(auto_write = TRUE)
options(mc.cores = 2)

data <- read_rdump("rundiff-park_2011.data.R")

fit <- stan("rundiff-park.stan", data = data,
            iter = 1000, chains = 4,
            seed = 561482)

saveRDS(fit, "rundiff-park_2011-fit.rds")
