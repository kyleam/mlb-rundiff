#!/usr/bin/Rscript

## * For teams with name changes, consistently use the new name.
##
## * Remove some unneeded fields.
##
## * Remove games completed at a later date.

library(dplyr)
library(readr)

glog <- read_csv("log-with-lags.csv")

## There are 25 games that were completed at a later date.  Drop them
## since play is split across multiple days.  These games are still
## acounted for in the lag calculations through spread_incomplete.py.
##
## filter(glog, !is.na(completion_info) &
##              between(lubridate::year(date), 1992, 2011))

glog %>%
    filter(is.na(completion_info) & game_id != "I") %>%
    select(-starts_with("umpire"),
           -starts_with("home_manager"),
           -starts_with("away_manager"),
           -starts_with("winning_pitcher"),
           -starts_with("losing_pitcher"),
           -starts_with("saving_pitcher"),
           -starts_with("game_winning"),
           -contains("batting"),
           -ends_with("team_league"),
           -ends_with("_pitchers"),
           -attendence, -day_of_week) %>%
    mutate_at(c("home_team", "away_team"),
              function (team)
                  case_when(team == "CAL" ~ "ANA",
                            team == "MON" ~ "WAS",
                            TRUE ~ team)) %>%
    write_csv("log-with-lags-cleaned.csv")
