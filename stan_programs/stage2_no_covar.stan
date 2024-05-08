// STAN implementation of BYM2 without covariates
functions {
  // ICAR model with sparse representation
  // @param phi vector of ICAR random effects
  // @param N number unique counties
  // @param node1 ordered adjacency matrix column 1
  // @param node2 ordered adjacency matrix column 2 (node2 > node1)
  real icar_normal_lpdf(vector phi, int N, int[] node1, int[] node2) {
    return -0.5 * dot_self(phi[node1] - phi[node2]) +
      normal_lpdf(sum(phi) | 0, 0.001 * N);
  }
}


data {
  // data size and outcomes
  int<lower = 1> n;           // Number of counties
  int<lower = 1> s;           // Number of states
  int<lower = 1> m;           // Number of obs (2 * n)
  int<lower = 0> y[m];        // Observed values
  vector[m] log_offset;       // log offset for each obs y
  matrix[m, s] state_mat_idx; // State indicators correspond to y
  vector[m] d1_idx;           // Race 1 indicator corresponding to y
  vector[m] d2_idx;           // Race 2 indicator corresponding to y
  vector[n] phi_hat;          // Fitted spatial effects from combined data model
  
  // adjacency matrix
  int W_n;                        // Number of edges
  int W_adj1[W_n];                // Edge list 1 (one column of adjacency pairs)
  int W_adj2[W_n];                // Edge list 2 (other column of adjacency pairs)
  
  // scaling factor
  real<lower = 0> scaling_factor; // scales the variance of the spatial effects
}


parameters {
  real alpha1;                // White intercept
  real alpha2;                // Black intercept
  vector[s] nu;               // state random effect
  real<lower = 0> sigma_s;    // state effect variance
  // real<lower = 0> delta;   // Scaling of shared component (phi_hat)
  
  vector[n] psi1;             // White spatial random effects
  vector[n] psi2;             // Black spatial random effects
  // vector[n] theta1;        // White non spatial random effects
  // vector[n] theta2;        // Black non spatial random effects
  real<lower = 0> sigma1;     // BYM2 scaling for White
  real<lower = 0> sigma2;     // BYM2 scaling for Black
  real logit_rho1;            // BYM2 spatial vs non spatial random effect for White
  real logit_rho2;            // BYM2 spatial vs non spatial random effect for Black
    
}


transformed parameters {
  real<lower=0, upper=1> rho1 = inv_logit(logit_rho1);
  real<lower=0, upper=1> rho2 = inv_logit(logit_rho2);
  vector[m] convolved_re_sigma = rep_vector(0, m);
  
  // random effects component
  // first half of vector for White
  convolved_re_sigma[1:n] = sigma1 / sqrt(scaling_factor) * (sqrt(rho1) * psi1 +
                       sqrt(1 - rho1) * phi_hat);
  // second half of vector for Black
  convolved_re_sigma[(n + 1):m] =  sigma2 / sqrt(scaling_factor) * (sqrt(rho2) * psi2 + 
                            sqrt(1 - rho2) * phi_hat);
}


model {
  y ~ poisson_log(log_offset + 
                  alpha1 * d1_idx + alpha2 * d2_idx + 
                  state_mat_idx * nu +
                  // phi_hat .* d1_idx * delta +
                  // phi_hat .* d2_idx / delta +
                  convolved_re_sigma
                  );
  // fixed effects
  alpha1 ~ normal(0, 10);
  alpha2 ~ normal(0, 10);
  // random effect of state
  nu ~ normal(0, sigma_s);
  sigma_s ~ normal(0, 5);
  // delta ~ lognormal(0, .4117);
  
  // spatial random effects
  psi1 ~ icar_normal_lpdf(W_n, W_adj1, W_adj2);
  psi2 ~ icar_normal_lpdf(W_n, W_adj1, W_adj2);
  // theta1 ~ normal(0, 1);
  // theta2 ~ normal(0, 1);
  logit_rho1 ~ normal(0, 1);
  logit_rho2 ~ normal(0, 1);
  sigma1 ~ normal(0, 1);
  sigma2 ~ normal(0, 1);
}
