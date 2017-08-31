
library(rstan)

rstan_options(auto_write = TRUE)
options(mc.cores = 2)

data <- read_rdump("rundiff-lagwe_2011.data.R")

fit <- stan("rundiff-lagwe.stan", data = data,
            iter = 1000, chains = 4,
            seed = 23684356)

saveRDS(fit, "rundiff-lagwe_2011-fit.rds")
