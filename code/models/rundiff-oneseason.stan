
data {
  int<lower=1> n_games;
  int<lower=1> n_teams;
  int<lower=1,upper=n_teams> team_home[n_games];
  int<lower=1,upper=n_teams> team_away[n_games];

  vector[n_games] rundiff;

  real df;
}

parameters {
  real<lower=0> sigma_a;
  real<lower=0> sigma_y;
  vector[n_teams] a_std;
}

transformed parameters {
  vector[n_teams] a;
  a = sigma_a * a_std;
}

model {
  a_std ~ normal(0, 1);
  sigma_y ~ normal(0, 6);
  sigma_a ~ normal(0, 3);

  for (i in 1:n_games)
    rundiff[i] ~ student_t(df, a[team_home[i]] - a[team_away[i]], sigma_y);
}
