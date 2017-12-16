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

glog <- read_csv("../../output/lag/log-with-lags-cleaned.csv") %>%
    mutate(yr = year(date))

cut_periods <- function(x, n_periods = 6){
    cut(x, breaks = seq(1, max(x) + 1, length.out = n_periods + 1),
        right = FALSE, labels = FALSE)
}

seasons <- glog %>%
    filter(between(yr, year_beg, year_end)) %>%
    mutate(home_team_yr = factor(paste0(home_team, "_", yr)),
           away_team_yr = factor(paste0(away_team, "_", yr),
                                 levels = levels(home_team_yr)),
           lag_toeast_home = lag_home > 1,  # traveling east
           lag_towest_home = lag_home < -1,
           lag_toeast_away = lag_away > 1,
           lag_towest_away = lag_away < -1,
           park_id = factor(park_id))

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

## We need to deal with seasons that have fewer than ~162 games (in
## particular, 94-95 due to the strike).  We could continue to split
## by the 162 games periods, but this requires the Stan model to
## support a jagged abilities structure (see rundiff-lagwe-flat.stan).
## Instead, use the same number of splits for all years, with fewer
## games per period for the strike years.
periods <- seasons %>%
    gather(team_type, team, home_team_yr, away_team_yr) %>%
    mutate(team = factor(team),
           team_type = factor(team_type),
           game_number = ifelse(team_type == "home_team_yr",
                                home_team_game_number,
                                away_team_game_number)) %>%
    group_by(team) %>%
    mutate(period = cut_periods(game_number)) %>%
    ungroup() %>%
    select(team, team_type, game_number, period)

dat <- seasons %>%
    full_join(filter(periods, team_type == "home_team_yr"),
              by = c("home_team_yr" = "team",
                     "home_team_game_number" = "game_number")) %>%
    rename(period_home = period) %>%
    full_join(filter(periods, team_type == "away_team_yr"),
              by = c("away_team_yr" = "team",
                     "away_team_game_number" = "game_number")) %>%
    rename(period_away = period) %>%
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
dat$n_pitchers <- nrow(pitchers)
dat$prior_score <- prior_score$score

rstan::stan_rdump(names(dat), envir = list2env(dat),
                  file = paste0("../../output/models/rundiff-lagwe_",
                                year_beg, "-", year_end, ".data.R"))

info <- list(team_names = levels(seasons$home_team_yr),
             pitchers = pitchers,
             parks = levels(seasons$park_id),
             wins = count_wins(seasons, yr, team))

dump(names(info), envir = list2env(info),
     file = paste0("../../output/models/rundiff-lagwe_",
                   year_beg, "-", year_end, ".info.R"))
