
library(rstan)

rstan_options(auto_write = TRUE)
options(mc.cores = 2)

data <- read_rdump("../../output/models/rundiff-lagwe_1992-2011.data.R")

fit <- stan("rundiff-lagwe.stan", data = data,
            seed = 38018,
            control = list(adapt_delta = 0.95,
                           max_treedepth = 15))

saveRDS(fit, "../../output/models/rundiff-lagwe_1992-2011-fit.rds")
