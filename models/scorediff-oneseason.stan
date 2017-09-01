
data {
  int<lower=1> n_games;
  int<lower=1> n_teams;
  int<lower=1,upper=n_teams> home[n_games];
  int<lower=1,upper=n_teams> away[n_games];

  vector[n_games] score_diff;

  real df;
}

parameters {
  real<lower=0> sigma_a;
  real<lower=0> sigma_y;
  vector[n_teams] eta_a;
}

transformed parameters {
  vector[n_teams] a;
  a = sigma_a * eta_a;
}

model {
  eta_a ~ normal(0, 1);
  sigma_y ~ normal(0, 6);
  sigma_a ~ normal(0, 3);

  for (i in 1:n_games){
    score_diff[i] ~ student_t(df, a[home[i]] - a[away[i]], sigma_y);
  }
}
