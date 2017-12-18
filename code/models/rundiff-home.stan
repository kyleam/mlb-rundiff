
data {
  int<lower=1> n_games;
  vector[n_games] rundiff;
}

parameters {
  real<lower=0> sigma_y;
  real<lower=1> nu;

  real<lower=0> b_home;
}

model {
  sigma_y ~ normal(0, 6);
  nu ~ gamma(2, 0.1);
  b_home ~ normal(0, 5);

  rundiff ~ student_t(nu, b_home, sigma_y);
}
