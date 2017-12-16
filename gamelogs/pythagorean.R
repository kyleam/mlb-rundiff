#!/usr/bin/env Rscript

## https://www.sports-reference.com/blog/baseball-reference-faqs/
##
##     What is pythagorean winning percentage?
##
##     Pythagorean winning percentage is an estimate of a team's
##     winning percentage given their runs scored and runs allowed.
##     Developed by Bill James, it can tell you when teams were a bit
##     lucky or unlucky.  It is calculated by
##
##                    (Runs Scored)^1.83
##     ---------------------------------------------------------
##      (Runs Scored)^1.83 +  (Runs Allowed)^1.83
##
##     The traditional formula uses an exponent of two, but this has
##     proven to be a little more accurate.

library(dplyr)
library(lubridate)
library(readr)
library(tidyr)

cnames <- scan("game-log-header.txt", character(), quiet = TRUE)
glog <- read_csv("1990_2016.csv", col_names = cnames) %>%
    mutate(date = ymd(date))

runs <- glog %>%
    select(date, home_team, away_team, home_runs_scored, away_runs_scored) %>%
    gather(team_type, team, home_team, away_team) %>%
    mutate(yr = as.integer(year(date)),
           runs_scored = ifelse(team_type == "home_team",
                                home_runs_scored,
                                away_runs_scored),
           runs_allowed = ifelse(team_type == "home_team",
                                 away_runs_scored,
                                 home_runs_scored)) %>%
    group_by(yr, team) %>%
    summarise(n_games = n(),
              scored = sum(runs_scored),
              allowed = sum(runs_allowed)) %>%
    ungroup() %>%
    mutate(pyth = scored^1.83 / (scored^1.83 + allowed^1.83),
           wins = round(162 * pyth))

write_csv(runs, "wins-pythagorean.csv")
