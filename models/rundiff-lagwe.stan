/*
 * Like rundiff-park.stan, but add lag information.
 */

data {
  int<lower=1> n_games;

  int<lower=1> n_teams;
  int<lower=1,upper=n_teams> team_home[n_games];
  int<lower=1,upper=n_teams> team_away[n_games];

  int<lower=2> n_periods;
  int<lower=1> period_home[n_games];
  int<lower=1> period_away[n_games];

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

parameters {
  real<lower=0> tau_y;
  real<lower=0> mu_sigma_y;
  vector<lower=0>[n_parks] sigma_y_std;

  real<lower=1> nu;

  real<lower=0> sigma_theta;
  vector[n_teams] theta;

  real<lower=0> tau_a;
  vector<lower=0>[n_teams] sigma_a_std;

  real b_home;
  real b_prev;

  real b_toeast;
  real b_towest;

  real<lower=0> sigma_gamm;
  vector[n_pitchers] gamm_std;

  vector[n_teams] a_std[n_periods];
}

transformed parameters {
  vector[n_teams] a[n_periods];
  vector[n_pitchers] gamm;
  vector<lower=0>[n_teams] sigma_a;
  vector<lower=0>[n_parks] sigma_y;

  for (k in 1:n_teams)
    sigma_a[k] = tau_a * sigma_a_std[k];

  for (m in 1:n_parks)
    sigma_y[m] = mu_sigma_y + tau_y * sigma_y_std[m];

  for (j in 1:n_periods)
    a[j] = theta + sigma_a .* a_std[j];

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

  tau_a ~ normal(0, 2);
  sigma_a_std ~ normal(0, 1);

  for (j in 1:n_periods)
    a_std[j] ~ normal(0, 1);

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
      mu_home[i] = a[period_home[i], team_home[i]] +
        gamm[pitcher_home[i]] +
        b_towest * lag_towest_home[i] +
        b_toeast * lag_toeast_home[i] +
        b_home;
      mu_away[i] = a[period_away[i], team_away[i]] +
        gamm[pitcher_away[i]] +
        b_towest * lag_towest_away[i] +
        b_toeast * lag_toeast_away[i];
      sy[i] = sigma_y[park[i]];
    }
    rundiff ~ student_t(nu, mu_home - mu_away, sy);
  }
}
