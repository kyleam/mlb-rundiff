
require(dplyr)

## Return win totals for each team.
##
## The data frame log_df should have the columns "home_team",
## "away_team", "home_runs_scored", and "away_runs_scored".
##
count_wins <- function(log_df){
    log_df %>%
        mutate(home_win = home_runs_scored > away_runs_scored) %>%
        gather(team_type, team, away_team:home_team) %>%
        mutate(win = case_when(home_win & team_type == "home_team"  ~ TRUE,
                               home_win ~ FALSE,
                               team_type == "away_team" ~ TRUE,
                               TRUE ~ FALSE)) %>%
        group_by(team) %>%
        summarise(n_wins = sum(win), n_games = n())
}
