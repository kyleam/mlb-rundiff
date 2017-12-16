
sim <- readRDS("../../output/models/rundiff-lagwe_1992-2011-sim.rds")
dat <- rstan::read_rdump("../../output/models/rundiff-lagwe_1992-2011.data.R")

bounds <- t(apply(sim, 2, quantile,
                  probs = c(0.025, 0.975), names = FALSE))

cat("Raw\n")
print(mean(dat$rundiff >= bounds[,1] &
           dat$rundiff <= bounds[,2]))

cat("\nRounded\n")
print(mean(dat$rundiff >= round(bounds[,1]) &
           dat$rundiff <= round(bounds[,2])))
