/*
 * Using the run differential of MLB games, estimate the ability of
 * teams, split across different periods of a season or seasons.
 *
 * This model is based on Milad Kharratzadeh's English Premier League
 * model, with a week corresponding to a period.
 *
 *   https://github.com/milkha/EPL/blob/master/epl_model.stan
 */

data {
  int<lower=1> n_games;

  int<lower=1> n_teams;
  int<lower=1,upper=n_teams> team_home[n_games];
  int<lower=1,upper=n_teams> team_away[n_games];

  int<lower=2> n_periods;
  int<lower=1> period_home[n_games];
  int<lower=1> period_away[n_games];

  row_vector[n_teams] prior_score;
  vector[n_games] rundiff;
}

parameters {
  real<lower=0> sigma_y;
  real<lower=1> nu;

  real<lower=0> sigma_mu_a;
  vector[n_teams] mu_a;

  real<lower=0> tau;
  vector<lower=0>[n_teams] sigma_a_std;

  real b_home;
  real b_prev;

  vector[n_teams] a_std[n_periods];
}

transformed parameters {
  vector[n_teams] a[n_periods];
  vector<lower=0>[n_teams] sigma_a;

  for (k in 1:n_teams)
    sigma_a[k] = tau * sigma_a_std[k];

  for (j in 1:n_periods)
    a[j] = mu_a + sigma_a .* a_std[j];
}

model {
  b_home ~ normal(0, 2);
  b_prev ~ normal(0, 2);

  tau ~ normal(0, 2);

  sigma_a_std ~ normal(0, 1);
  for (j in 1:n_periods)
    a_std[j] ~ normal(0, 1);

  sigma_mu_a ~ normal(0, 2);
  mu_a ~ normal(prior_score * b_prev, sigma_mu_a);

  sigma_y ~ normal(0, 6);
  nu ~ gamma(2, 0.1);

  {
    vector[n_games] a_diff;

    for (i in 1:n_games){
      a_diff[i] = a[period_home[i], team_home[i]] -
        a[period_away[i], team_away[i]];
    }
    rundiff ~ student_t(nu, a_diff + b_home, sigma_y);
  }
}

generated quantities {
  vector[n_games] rundiff_new;

  {
    vector[n_games] a_diff_new;
    for (i in 1:n_games){
      a_diff_new[i] = a[period_home[i], team_home[i]] -
        a[period_away[i], team_away[i]];
      rundiff_new[i] = student_t_rng(nu, a_diff_new[i] + b_home, sigma_y);
    }
  }
}
