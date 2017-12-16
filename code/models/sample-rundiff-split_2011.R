
library(rstan)

rstan_options(auto_write = TRUE)
options(mc.cores = 2)

data <- read_rdump("../../output/models/rundiff-split_2011.data.R")

fit <- stan("rundiff-split.stan", data = data,
            iter = 1000, chains = 4,
            seed = 193531279)

saveRDS(fit, "../../output/models/rundiff-split_2011-fit.rds")
