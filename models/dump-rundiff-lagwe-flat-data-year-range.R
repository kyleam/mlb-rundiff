#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2){
    stop("usage: dump-rundiff-lagwe-data-year-range.R <year-start> <year-end>")
}
year_beg <- as.integer(args[1])
year_end <- as.integer(args[2])

library(dplyr)
library(lubridate)
library(readr)
library(tidyr)

source("../lib/utils.R")

glog <- read_csv("../lag/log-with-lags-cleaned.csv") %>%
    mutate(yr = year(date))

cut_periods <- function(x){
    cut(x, breaks = seq(1, 169, by = 21), right = FALSE, labels = FALSE)
}

seasons <- glog %>%
    filter(between(yr, year_beg, year_end)) %>%
    mutate(home_team_yr = factor(paste0(home_team, "_", yr)),
           away_team_yr = factor(paste0(away_team, "_", yr),
                                 levels = levels(home_team_yr)),
           period_home = cut_periods(home_team_game_number),
           period_away = cut_periods(away_team_game_number),
           lag_toeast_home = lag_home > 1,  # traveling east
           lag_towest_home = lag_home < -1,
           lag_toeast_away = lag_away > 1,
           lag_towest_away = lag_away < -1,
           park_id = factor(park_id))

period_size <- seasons %>%
    gather(team_type, team, home_team, away_team) %>%
    mutate(period = ifelse(team_type == "home_team",
                           period_home,
                           period_away)) %>%
    group_by(team, yr) %>%
    summarise(size = max(period))
stopifnot(paste0(period_size$team, "_", period_size$yr) ==
          levels(seasons$home_team_yr))

prior_score <- glog %>%
    filter(between(yr, year_beg - 1, year_end - 1)) %>%
    count_wins(team, yr) %>%
    group_by(yr) %>%
    mutate(score = scales::rescale(n_wins, to = c(-1, 1)),
           team_yr = paste0(team, "_", yr + 1)) %>%
    ungroup() %>%
    ## Set score of new teams to 0.
    full_join(tibble(team_yr = levels(seasons$home_team_yr))) %>%
    mutate(score = coalesce(score, 0)) %>%
    arrange(team_yr)
stopifnot(prior_score$team_yr == levels(seasons$home_team_yr))

pitchers <- select(seasons,
                   home_starting_pitcher_id,
                   away_starting_pitcher_id,
                   home_starting_pitcher_name,
                   away_starting_pitcher_name) %>%
    unlist() %>%
    matrix(nrow = nrow(seasons) * 2) %>%
    as_tibble() %>%
    setNames(c("id", "name")) %>%
    distinct(id) %>%
    arrange(id)

dat <- seasons %>%
    transmute(team_home = as.integer(home_team_yr),
              team_away = as.integer(away_team_yr),
              period_home = period_home,
              period_away = period_away,
              park = as.integer(park_id),
              lag_toeast_home = as.integer(lag_toeast_home),
              lag_towest_home = as.integer(lag_towest_home),
              lag_toeast_away = as.integer(lag_toeast_away),
              lag_towest_away = as.integer(lag_towest_away),
              pitcher_home = as.integer(factor(home_starting_pitcher_id,
                                               levels = pitchers$id)),
              pitcher_away = as.integer(factor(away_starting_pitcher_id,
                                               levels = pitchers$id)),
              rundiff = home_runs_scored - away_runs_scored) %>%
    as.list()
dat$n_games <- length(dat$rundiff)
dat$n_teams <- n_distinct(dat$team_home)
dat$n_parks <- n_distinct(dat$park)
dat$n_periods <- max(dat$period_home)
dat$period_size <- period_size$size
dat$n_pitchers <- nrow(pitchers)
dat$prior_score <- prior_score$score

rstan::stan_rdump(names(dat), envir = list2env(dat),
                  file = paste0("rundiff-lagwe-flat_",
                                year_beg, "-", year_end, ".data.R"))

info <- list(team_names = levels(seasons$home_team_yr),
             pitchers = pitchers,
             parks = levels(seasons$park_id),
             wins = count_wins(seasons, yr, team))

dump(names(info), envir = list2env(info),
     file = paste0("rundiff-lagwe-flat_",
                   year_beg, "-", year_end, ".info.R"))
