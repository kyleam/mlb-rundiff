/*
 * Like rundiff-lagwe.stan, but teams don't need to have the same
 * number of periods.
 */

data {
  int<lower=1> n_games;

  int<lower=1> n_teams;
  int<lower=1,upper=n_teams> team_home[n_games];
  int<lower=1,upper=n_teams> team_away[n_games];

  int<lower=2> n_periods;
  int<lower=1> period_home[n_games];
  int<lower=1> period_away[n_games];
  int period_size[n_teams];

  int<lower=1> n_parks;
  int<lower=1,upper=n_parks> park[n_games];

  int<lower=0,upper=2> lag_toeast_home[n_games];
  int<lower=0,upper=2> lag_towest_home[n_games];
  int<lower=0,upper=2> lag_toeast_away[n_games];
  int<lower=0,upper=2> lag_towest_away[n_games];

  int n_pitchers;
  int<lower=1,upper=n_pitchers> pitcher_home[n_games];
  int<lower=1,upper=n_pitchers> pitcher_away[n_games];

  row_vector[n_teams] prior_score;
  vector[n_games] rundiff;
}

transformed data {
  int a_size;
  int a_offset[n_teams];

  a_size = sum(period_size);

  a_offset[1] = 0;
  for (k in 2:n_teams){
    a_offset[k] = a_offset[k - 1] + period_size[k - 1];
  }
}

parameters {
  real<lower=0> tau_y;
  real<lower=0> mu_sigma_y;
  vector<lower=0>[n_parks] sigma_y_std;

  real<lower=1> nu;

  real<lower=0> sigma_theta;
  vector[n_teams] theta;

  real<lower=0> sigma_a;

  real b_home;
  real b_prev;

  real b_toeast;
  real b_towest;

  real<lower=0> sigma_gamm;
  vector[n_pitchers] gamm_std;

  vector[a_size] a_std;
}

transformed parameters {
  vector[n_pitchers] gamm;
  vector<lower=0>[n_parks] sigma_y;
  /*
   * The abilities, which are conceptually n_periods x n_teams, are
   * represented as a flat array to handle jagged period values that
   * can occur across seasons when a new team enters the league.
   */
  vector[a_size] a;

  for (m in 1:n_parks)
    sigma_y[m] = mu_sigma_y + tau_y * sigma_y_std[m];

  {
    int idx_base;

    for (k in 1:n_teams){
      idx_base = a_offset[k];
      for (s in 1:period_size[k]){
        a[idx_base + s] = theta[k] + sigma_a * a_std[idx_base + s];
      }
    }
  }

  for (l in 1:n_pitchers)
    gamm[l] = sigma_gamm * gamm_std[l];
}

model {
  b_home ~ normal(0, 2);
  b_prev ~ normal(0, 2);

  b_toeast ~ normal(0, 2);
  b_towest ~ normal(0, 2);

  sigma_gamm ~ normal(0, 2);
  gamm_std ~ normal(0, 1);

  sigma_a ~ normal(0, 2);
  a_std ~ normal(0, 1);

  sigma_theta ~ normal(0, 2);
  theta ~ normal(prior_score * b_prev, sigma_theta);

  mu_sigma_y ~ normal(0, 5);
  tau_y ~ normal(0, 3);
  sigma_y_std ~ normal(0, 1);

  nu ~ gamma(2, 0.1);

  {
    vector[n_games] mu_home;
    vector[n_games] mu_away;
    vector[n_games] sy;

    for (i in 1:n_games){
      mu_home[i] = a[a_offset[team_home[i]] + period_home[i]] +
        gamm[pitcher_home[i]] +
        b_towest * lag_towest_home[i] +
        b_toeast * lag_toeast_home[i] +
        b_home;
      mu_away[i] = a[a_offset[team_away[i]] + period_away[i]] +
        gamm[pitcher_away[i]] +
        b_towest * lag_towest_away[i] +
        b_toeast * lag_toeast_away[i];
      sy[i] = sigma_y[park[i]];
    }
    rundiff ~ student_t(nu, mu_home - mu_away, sy);
  }
}
