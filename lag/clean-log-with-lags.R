#!/usr/bin/Rscript

## * For teams with name changes, consistently use the new name.
##
## * Remove some unneeded fields.
##
## * Remove games completed at a later date.

library(dplyr)
library(readr)

gl <- read_csv("log-with-lags.csv")

## There are 25 games that were completed at a later date.  I'm not
## sure how to treat the lags in these cases because the game is split
## across days.  Another issue is that these could affect the lags of
## other entries if a make-up game happened on a day that is being
## counted as a day off.  The lag calculation should at least account
## for the latter issue.  Drop them for now.
##
## filter(gl, !is.na(CompletionInfo))

gl %>%
    filter(is.na(CompletionInfo)) %>%
    select(-starts_with("Umpire"),
           -contains("Batting"),
           -ends_with("Name"),
           -ends_with("ID", ignore.case = FALSE),
           -ends_with("TeamGameNumber"),
           -ends_with("TeamLeague"),
           -ends_with("Pitchers"),
           -Attendence, -DayOfWeek) %>%
    mutate_at(c("home", "away"),
              function (team)
                  case_when(team == "CAL" ~ "ANA",
                            team == "MON" ~ "WAS",
                            TRUE ~ team)) %>%
    write_csv("log-with-lags-cleaned.csv")
