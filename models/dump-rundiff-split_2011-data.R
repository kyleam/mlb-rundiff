
library(dplyr)
library(lubridate)
library(readr)
library(tidyr)

source("../lib/utils.R")

glog <- read_csv("../lag/log-with-lags-cleaned.csv")

prior_score <- glog %>%
    filter(year(date) == 2010) %>%
    count_wins %>%
    mutate(team = factor(team),
           score = scales::rescale(n_wins, to = c(-1, 1)))

cut_periods <- function(x){
    cut(x, breaks = seq(1, 169, by = 21), right = FALSE, labels = FALSE)
}

season <- glog %>%
    filter(year(date) == 2011) %>%
    mutate(home_team = factor(home_team),
           away_team = factor(away_team, levels = levels(home_team)))
stopifnot(levels(season$home_team) == levels(season$away_team))

dat <- season %>%
    transmute(team_home = as.integer(home_team),
              team_away = as.integer(away_team),
              period_home = cut_periods(home_team_game_number),
              period_away = cut_periods(away_team_game_number),
              rundiff = home_runs_scored - away_runs_scored) %>%
    as.list()
dat$n_games <- length(dat$rundiff)
dat$n_teams <- n_distinct(dat$team_home)
dat$n_periods <- max(dat$period_home)
dat$prior_score <- prior_score$score

rstan::stan_rdump(names(dat), envir = list2env(dat),
                  file = "rundiff-split_2011.data.R")

team_names <- levels(season$home_team)
wins_2011 <- count_wins(filter(glog, year(date) == 2011))

dump(c("team_names", "wins_2011"), file = "rundiff-split_2011.info.R")
