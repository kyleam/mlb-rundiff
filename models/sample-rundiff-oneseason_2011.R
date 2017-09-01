
library(rstan)

rstan_options(auto_write = TRUE)
options(mc.cores = 2)

data <- read_rdump("rundiff-oneseason_2011.data.R")

fit <- stan("rundiff-oneseason.stan", data = data,
            iter = 1000, chains = 4,
            seed = 237927581)

saveRDS(fit, "rundiff-oneseason_2011-fit.rds")
