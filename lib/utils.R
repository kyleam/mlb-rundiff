
require(dplyr)
require(tidyr)

## Return win totals for each team.
##
## Arguments:
##
##   log_df: data frame that includes the columns "home_team",
##           "away_team", "home_runs_scored", and "away_runs_scored".
##
##      ...: arguments passed to `dplyr::group_by`.  If not specified,
##           `team` will be used.
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
## Arguments:
##
##        arr: an array with the first dimension of corresponding to
##             iterations or a vector, which will be treated as a one
##             dimensional array.
##
##   varnames: a vector of names for each dimension of `arr` except
##             for the first.
##
##      probs: passed to `quantile` and, if unspecified, is set to
##             values that can be used to define the 50%, 80%, and 95%
##             bounds.
trace_intervals <- function(arr, varnames, probs = NULL){
    dims <- dim(arr)
    nd <- length(dims)
    if (nd > 1 && length(varnames) != nd - 1)
        stop("varnames is not the correct length")

    if (is.null(probs))
        probs <- c(0.025, 0.1, 0.25, 0.75, 0.9, 0.975)

    agg_fn <- function(x){
        c(mean(x),
          quantile(x, probs, names = FALSE))
    }

    if (nd < 2){
        result <- agg_fn(arr)
        names(result) <- c("mean", paste0("p", probs * 100))
        return(result)
    }
    result <- apply(arr, 2:nd, agg_fn)
    rownames(result) <- c("mean", paste0("p", probs * 100))
    as_tibble(spread(reshape2::melt(result, varnames = c("measure", varnames)),
                     measure, value))
}

## Calculate the probability of a home team win using a scaled
## t-distribution.
##
## A run differential above zero is considered a win for the home
## team.
##
## Arguments:
##
##   nu, mu, sigma: parameters matching Stan's `student_t` function.
##
##     home: if FALSE, report the probability of an away team win
##           instead.
rundiff_pwin <- function(nu, mu, sigma, home = TRUE){
    pt(-mu / sigma, nu, lower.tail = !home)
}
