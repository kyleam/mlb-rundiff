
library(dplyr)
library(readr)

glog <- read_csv("../../output/lag/log-with-lags-cleaned.csv")

season <- glog %>%
    filter(lubridate::year(date) == 2011) %>%
    mutate(home_team = factor(home_team),
           away_team = factor(away_team, levels = levels(home_team)))
stopifnot(levels(season$home_team) == levels(season$away_team))

dat <- season %>%
    transmute(team_home = as.integer(home_team),
              team_away = as.integer(away_team),
              rundiff = home_runs_scored - away_runs_scored) %>%
    as.list()
dat$n_games <- length(dat$rundiff)
dat$n_teams <- n_distinct(dat$team_home)
dat$df <- 7

rstan::stan_rdump(names(dat),
                  envir = list2env(dat),
                  file = "../../output/models/rundiff-oneseason_2011.data.R")

team_names <- levels(season$home_team)
dump(c("team_names"),
     file = "../../output/models/rundiff-oneseason_2011.info.R")
