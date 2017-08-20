
library(rstan)

rstan_options(auto_write = TRUE)
options(mc.cores = 2)

data <- read_rdump("scorediff-oneseason-2011.data.R")

fit <- stan("scorediff-oneseason.stan", data = data,
            sample_file = "scorediff-oneseason-2011-samples.csv",
            iter = 1000, chains = 4,
            seed = 237927581)
