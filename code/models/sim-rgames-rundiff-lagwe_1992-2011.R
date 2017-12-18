
library(dplyr)
library(stringr)

sim <- readRDS("../../outputs/models/rundiff-lagwe_1992-2011-sim.rds")

dat <- rstan::read_rdump("../../outputs/models/rundiff-lagwe_1992-2011.data.R")
info <- rstan::read_rdump("../../outputs/models/rundiff-lagwe_1992-2011.info.R")

years <- c(1992, 1996, 2000, 2003, 2007, 2011)

game_years <- str_split_fixed(info$team_names[dat$team_hom], "_", 2)[,2] %>%
    as.integer()

n_games <- 40
set.seed(49925)
rand_games <- lapply(years,
                     function (x)
                         sample(which(game_years == x), n_games)) %>%
    unlist()

apply(sim[, rand_games], 2,
      quantile, probs = c(0.025, 0.975), names = FALSE) %>%
    t() %>%
    as_tibble() %>%
    setNames(c("p2.5", "p97.5")) %>%
    mutate(game = rand_games,
           year = game_years[game],
           obs = dat$rundiff[game],
           team_home = info$team_names[dat$team_home[game]],
           team_away = info$team_names[dat$team_away[game]]) %>%
    arrange(game) %>%
    saveRDS("../../outputs/models/rundiff-lagwe_1992-2011-sim-rgames.rds")
