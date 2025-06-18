// STAN implementation of BYM2: stage 1
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
  
  int<lower=1, upper=n> c_idx[m];  // maps each observation to a county 1:m
  
  // adjacency matrix
  int W_n;                         // Number of edges
  int W_adj1[W_n];                 // Edge list 1 (one column of adjacency pairs)
  int W_adj2[W_n];                 // Edge list 2 (other column of adjacency pairs)
  
  // scaling factor
  real<lower = 0> scaling_factor;  // scales the variance of the spatial effects
}


parameters {
  real alpha;                // Intercept
  vector[s] nu;              // State random effect
  real<lower = 0> sigma_s;   // State effect variance
  vector[n] phi;             // Spatial random effect
  real<lower = 0> sigma;     // BYM2 scaling for spatial random effect
}


transformed parameters {
  // random effects component
  vector[n] convolved_re = sqrt(1 / scaling_factor) * phi;
  
}


model {
  y ~ poisson_log(log_offset + 
                  alpha + state_mat_idx * nu + convolved_re[c_idx] * sigma);
  
  // fixed effects
  alpha ~ normal(0, 10);
  
  // random effect of state
  nu ~ normal(0, sigma_s);
  sigma_s ~ normal(0, 5);
  
  // spatial random effects
  phi ~ icar_normal_lpdf(W_n, W_adj1, W_adj2);
  sigma ~ normal(0, 1);
}
