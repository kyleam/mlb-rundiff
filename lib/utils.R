
require(dplyr)

## Return win totals for each team.
##
## The data frame log_df should have the columns "home_team",
## "away_team", "home_runs_scored", and "away_runs_scored".
##
count_wins <- function(log_df){
    log_df %>%
        mutate(home_win = home_runs_scored > away_runs_scored) %>%
        gather(team_type, team, away_team, home_team) %>%
        mutate(win = case_when(team_type == "home_team" & home_win ~ TRUE,
                               team_type == "away_team" & home_win  ~ FALSE,
                               team_type == "away_team" ~ TRUE,
                               team_type == "home_team"  ~ FALSE,
                               TRUE ~ NA)) %>%
        group_by(team) %>%
        summarise(n_wins = sum(win), n_games = n())
}

source_as_list <- function(file){
    source_env <- new.env()
    source(file, source_env)
    as.list(source_env)
}
