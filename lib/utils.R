
require(dplyr)
require(tidyr)

## Return win totals for each team.
##
## The data frame log_df should have the columns "home_team",
## "away_team", "home_runs_scored", and "away_runs_scored".
##
## The remaing arguments are variables to group by.  If not specified,
## `team' will be used.
count_wins <- function(log_df, ...){
    groups <- quos(...)
    if (length(groups) == 0){
        groups <- quos(team)
    }

    log_df %>%
        mutate(home_win = .data$home_runs_scored > .data$away_runs_scored) %>%
        gather(team_type, team, away_team, home_team) %>%
        mutate(win = case_when(
                   .data$team_type == "home_team" & .data$home_win ~ TRUE,
                   .data$team_type == "away_team" & .data$home_win  ~ FALSE,
                   .data$team_type == "away_team" ~ TRUE,
                   .data$team_type == "home_team"  ~ FALSE,
                   TRUE ~ NA)) %>%
        group_by(!!!groups) %>%
        summarise(n_wins = sum(.data$win), n_games = n())
}

## Compute quantiles and mean over the trace iterations
##
## `arr` is an array of at least two dimensions, with the first
##  dimension respresenting iterations.  `varnames` is a vector of
##  names for each dimension of `arr` except for the first.
##
## `probs` is passed to `quantile` and, if unspecified, is set to
## values that can be used to define the 50%, 80%, and 95% bounds.
trace_intervals <- function(arr, varnames, probs = NULL){
    nd <- length(dim(arr))
    if (length(varnames) != nd - 1)
        stop("varnames is not the correct length")

    if (is.null(probs))
        probs <- c(0.025, 0.1, 0.25, 0.75, 0.9, 0.975)

    result <- apply(arr, 2:nd,
                    function(x) c(mean = mean(x),
                                  quantile(x, probs, names = FALSE)))
    rownames(result)[2:nrow(result)] <- paste0("p", probs * 100)

    as_tibble(spread(reshape2::melt(result, varnames = c("measure", varnames)),
                     measure, value))
}
