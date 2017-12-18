
library(rstan)

rstan_options(auto_write = TRUE)
options(mc.cores = 2)

data <- read_rdump("../../outputs/models/rundiff-pitch_2011.data.R")

fit <- stan("rundiff-pitch.stan", data = data,
            iter = 1000, chains = 4,
            seed = 3524553)

saveRDS(fit, "../../outputs/models/rundiff-pitch_2011-fit.rds")
