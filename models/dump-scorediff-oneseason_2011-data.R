
library(dplyr)
library(readr)

glog <- read_csv("../lag/log-with-lags-cleaned.csv")

season <- glog %>%
    filter(lubridate::year(date) == 2011) %>%
    mutate(home_team = factor(home_team),
           away_team = factor(away_team, levels = levels(home_team)))
stopifnot(levels(season$home_team) == levels(season$away_team))

dat <- season %>%
    transmute(home = as.integer(home_team),
              away = as.integer(away_team),
              score_diff = home_runs_scored - away_runs_scored) %>%
    as.list()
dat$n_games <- length(dat$score_diff)
dat$n_teams <- n_distinct(dat$home)
dat$df <- 7

rstan::stan_rdump(c("n_games", "n_teams", "home", "away", "score_diff", "df"),
                  envir = list2env(dat),
                  file = "scorediff-oneseason_2011.data.R")

team_names <- levels(season$home_team)
dump(c("team_names"),
     file = "scorediff-oneseason_2011.info.R")
