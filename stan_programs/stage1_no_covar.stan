// STAN implementation of BYM2 for combined data without covariates
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
  int<lower = 0> y[n];        // Observed values
  vector[n] log_offset;         // log offset for each obs y
  matrix[n, s] state_mat_idx;    // State indicators correspond to y
  
  // adjacency matrix
  int W_n;                    // Number of edges
  int W_adj1[W_n];                 // Edge list 1 (one column of adjacency pairs)
  int W_adj2[W_n];                 // Edge list 2 (other column of adjacency pairs)
  
  // scaling factor
  real<lower = 0> scaling_factor; // scales the variance of the spatial effects
}


parameters {
  real alpha;                // Intercepts
  vector[s] nu;              // State random effect
  real<lower = 0> sigma_s;   // State effect variance
  vector[n] phi;             // spatial random effect
  vector[n] theta;           // nonspatial random effect
  real<lower = 0> sigma;     // BYM2 scaling
  real logit_rho;            // BYM2 spatial vs non spatial random effect 
}


transformed parameters {
  real<lower=0, upper=1> rho = inv_logit(logit_rho);
  // random effects component
  vector[n] convolved_re = sqrt(rho / scaling_factor) * phi + sqrt(1 - rho) * theta;
}


model {
  y ~ poisson_log(log_offset + 
                  alpha + state_mat_idx * nu + convolved_re * sigma);
  // fixed effects
  alpha ~ normal(0, 10);
  // random effect of state
  nu ~ normal(0, sigma_s);
  sigma_s ~ normal(0, 5);
  // spatial and non spatial random effects
  phi ~ icar_normal_lpdf(W_n, W_adj1, W_adj2);
  theta ~ normal(0, 1);
  sigma ~ normal(0, 1);
  logit_rho ~ normal(0, 1);
}
