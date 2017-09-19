#!/usr/bin/Rscript

library(dplyr)
library(lubridate)
library(readr)
library(tidyr)

lag <- read_csv("lag-combined-1990_2016.csv") %>%
    mutate(date = ymd(date))

lag_wide <- lag %>%
    separate(matchup, into = c("away_team", "home_team"), sep = "@") %>%
    mutate(lag_type = ifelse(team == home_team, "lag_home", "lag_away")) %>%
    select(-team, -tz_shift, -days_delta) %>%
    spread(lag_type, lag)

cnames <- scan("../gamelogs/game-log-header.txt", character(), quiet = TRUE)
glog <- read_csv("../gamelogs/1990_2016.csv", col_names = cnames,
                 col_types = list(game_id = col_character())) %>%
    mutate(date = ymd(date))

full_join(lag_wide, glog,
          by = c("date", "away_team", "home_team", "game_id")) %>%
    arrange(date, home_team, away_team, game_id) %>%
    write_csv("log-with-lags.csv")
