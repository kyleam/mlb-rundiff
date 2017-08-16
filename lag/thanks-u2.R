#!/usr/bin/Rscript

library(dplyr)
library(lubridate)
library(readr)

lag <- read_csv("lag-combined-sorted-1992_2011.csv") %>%
    mutate(date = ymd(date))

# Because of a U2 concert, this series was moved to Seattle.  We need
# to adjust the lags.

## lag %>%
##     filter(matchup == "SEA@FLO",
##            between(date, ymd("20110624"), ymd("20110626")))

## lag %>%
##     filter(team == "FLO",
##            between(date, ymd("20110620"), ymd("20110705")))
## lag %>%
##     filter(team == "SEA",
##            between(date, ymd("20110620"), ymd("20110705")))

## lag %>%
##     filter(team %in% c("SEA", "FLO"),
##            between(date, ymd("20110624"), ymd("20110630")))

u2 <- tribble(
      ~date, ~team, ~game_tz, ~lag,  ~matchup, ~tz_shift, ~days_delta, ~dbl_header,
 "20110624", "FLO",     "PT",   -2, "FLO@SEA",    "0->3",           2,           0,
 "20110625", "FLO",     "PT",   -1, "FLO@SEA",    "3->3",           1,           0,
 "20110626", "FLO",     "PT",    0, "FLO@SEA",    "3->3",           1,           0,
 "20110628", "FLO",     "PT",    0, "FLO@OAK",    "3->3",           2,           0,
 "20110629", "FLO",     "PT",    0, "FLO@OAK",    "3->3",           1,           0,
 "20110630", "FLO",     "PT",    0, "FLO@OAK",    "3->3",           1,           0,

 "20110624", "SEA",     "PT",   -3, "FLO@SEA",    "0->3",           1,           0,
 "20110625", "SEA",     "PT",   -2, "FLO@SEA",    "3->3",           1,           0,
 "20110626", "SEA",     "PT",   -1, "FLO@SEA",    "3->3",           1,           0,
 "20110627", "SEA",     "PT",    0, "ATL@SEA",    "3->3",           1,           0,
 "20110628", "SEA",     "PT",    0, "ATL@SEA",    "3->3",           1,           0,
 "20110629", "SEA",     "PT",    0, "ATL@SEA",    "3->3",           1,           0) %>%
    mutate(date = ymd(date))

lag_dropped <- anti_join(lag, u2, by = c("date", "team", "dbl_header"))
## lag_dropped %>%
##     filter(team %in% c("FLO", "SEA"),
##            between(date, ymd("20110624"), ymd("20110630")))

bind_rows(lag_dropped, u2) %>%
    arrange(date, matchup, team, dbl_header) %>%
    write_csv("lag-combined-u2-1992_2011.csv")
