#!/usr/bin/Rscript

## Simulate run differentials for rundiff-lagwe model.
##
## `data` matches the `data` parameter of the `stan` function.
## `samps` an array of MCMC samples as returned by
## `rstan::extract(permuted = TRUE, ...)`.
##
## `game_idx` can be given to restrict the simulation to a subset of
## games.
##
## Returns a matrix with [iterations, number of games] dimenions.
sim_rundiffs <- function(data, samps, game_idx = NULL){
    dd <- data
    if (!is.null(game_idx)){
        dd$team_home <- data$team_home[game_idx]
        dd$team_away <- data$team_away[game_idx]
        dd$period_home <- data$period_home[game_idx]
        dd$period_away <- data$period_away[game_idx]
        dd$pitcher_home <- data$pitcher_home[game_idx]
        dd$pitcher_away <- data$pitcher_away[game_idx]
        dd$lag_towest_home <- data$lag_towest_home[game_idx]
        dd$lag_toeast_home <- data$lag_toeast_home[game_idx]
        dd$lag_towest_away <- data$lag_towest_away[game_idx]
        dd$lag_toeast_away <- data$lag_toeast_away[game_idx]
        dd$park <- data$park[game_idx]
    }

    n_iter <- length(samps["lp__"][[1]])
    n_games <- length(dd$park)
    rundiff_sim <- matrix(data = NA, nrow = n_iter, ncol = n_games)
    for (i in 1:n_iter){
        mu_home <- samps$a[cbind(i, dd$period_home, dd$team_home)] +
            samps$gamm[cbind(i, dd$pitcher_home)] +
            samps$b_towest[i] * dd$lag_towest_home +
            samps$b_toeast[i] * dd$lag_toeast_home +
            samps$b_home[i]
        mu_away <- samps$a[cbind(i, dd$period_away, dd$team_away)] +
            samps$gamm[cbind(i, dd$pitcher_away)] +
            samps$b_towest[i] * dd$lag_towest_away +
            samps$b_toeast[i] * dd$lag_toeast_away

        rundiff_sim[i,] <- mu_home - mu_away +
            rt(n_games, samps$nu[i]) * samps$sigma_y[i, dd$park]
    }
    return(rundiff_sim)
}
