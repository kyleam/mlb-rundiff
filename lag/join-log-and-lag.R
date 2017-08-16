#!/usr/bin/Rscript

library(dplyr)
library(lubridate)
library(readr)
library(tidyr)

lag <- read_csv("lag-combined-u2-1992_2011.csv")
lag_wide <- lag %>%
    separate(matchup, into = c("away", "home"), sep = "@") %>%
    mutate(lag_type = ifelse(team == home, "lag_home", "lag_away")) %>%
    select(-team, -tz_shift, -days_delta) %>%
    spread(lag_type, lag)

cnames <- scan("../gamelogs/game_log_header.csv", character(), sep = ",",
               quiet = TRUE)
gl <- read_csv("../gamelogs/1992_2011.csv", col_names = cnames) %>%
    mutate(Date = ymd(Date)) %>%
    rename(date = Date, dbl_header = DoubleHeader,
           home = HomeTeam, away = VisitingTeam)

stopifnot(nrow(gl) == nrow(lag_wide))

## The entries don't match up for a SEA/FLO series that was played at
## SEA with FLO as the home team.  Drop the series (at least for now)
## because I'm not sure how it should be treated in the model.
##
## anti_join(lag_wide, gl, by = c("date", "away", "home", "dbl_header"))

inner_join(lag_wide, gl, by = c("date", "away", "home", "dbl_header")) %>%
    write_csv("log-with-lags.csv")
