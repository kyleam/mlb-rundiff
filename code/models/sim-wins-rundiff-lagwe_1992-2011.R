#!/usr/bin/env Rscript

library(dplyr)
library(tidyr)

sim <- readRDS("../../output/models/rundiff-lagwe_1992-2011-sim.rds")
dat <- rstan::read_rdump("../../output/models/rundiff-lagwe_1992-2011.data.R")
info <- rstan::read_rdump("../../output/models/rundiff-lagwe_1992-2011.info.R")

extract_wins <- function(team){
    games <- dat$team_home == team | dat$team_away == team
    sim_team <- sim[, games]

    toi_home <- dat$team_home[games] == team
    sim_team[,!toi_home] <- -sim_team[,!toi_home]
    apply(sim_team, 1, function (x) sum(x > 0))
}

teams <- c("BOS", "CIN", "HOU", "NYA", "PHI", "SEA", "SFN", "TEX")
years <- c("1992", "1996", "2000", "2003", "2007", "2011")
sel_teams <- as.vector(outer(teams, years,
                             function (x, y) paste0(x, "_", y)))
sel_team_ids <- sapply(sel_teams,
                       function (x) which(info$team_names == x))

lapply(sel_team_ids, extract_wins) %>%
    as_tibble() %>%
    mutate(iter = 1:n()) %>%
    gather(team_year, wins, -iter) %>%
    separate(team_year, c("team", "yr")) %>%
    mutate(yr = factor(as.integer(yr))) %>%
    saveRDS("../../output/models/rundiff-lagwe_1992-2011-sim-wins.rds")
