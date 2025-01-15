## load packages ----
#library(devtools)
library(remotes)

# now install and run INLA
# note: had version issues with FASSE, so I'm installing an order version
# also note: this older version seems to have conflicts with other packages (possibly rstan)
# I had to delete all other packages in order to install this
if (!require(INLA)) {
  remotes::install_version("INLA", version = "22.05.07", 
                           repos = c(getOption("repos"),
                                     INLA = "https://inla.r-inla-download.org/R/testing"),
                           dep = TRUE)
}
library(INLA)


#--- this code comes directly from the Scotland Lip Cancer dataset example here:
# https://mc-stan.org/users/documentation/case-studies/icar_stan.html (Morris 2019)


# load county adjacency data
county_adj_sparse_list <- read_rds("data/symlinks/scratch/county_adj_sparse_list.rds")

# number of edges
W_n = nrow(county_adj_sparse_list$W_sparse)
# first column of edge list
W_adj1 = county_adj_sparse_list$W_sparse[,1]
# second column of edge list
W_adj2 = county_adj_sparse_list$W_sparse[,2]

N <- length(county_adj_sparse_list$D_sparse)

# Build the adjacency matrix using INLA library functions
adj.matrix <- sparseMatrix(i = W_adj1,
                          j = W_adj2,
                          x = 1,
                          symmetric = TRUE)

# The ICAR precision matrix (note! This is singular)
Q <- Diagonal(N, rowSums(adj.matrix)) - adj.matrix
# Add a small jitter to the diagonal for numerical stability (optional but recommended)
Q_pert <- Q + Diagonal(N) * max(diag(Q)) * sqrt(.Machine$double.eps)

# Compute the diagonal elements of the covariance matrix subject to the 
# constraint that the entries of the ICAR sum to zero.
# See the inla.qinv function help for further details.
Q_inv <- inla.qinv(Q_pert, constr=list(A = matrix(1,1,N),e=0))

# Compute the geometric mean of the variances, which are on the diagonal of Q.inv
scaling_factor <- exp(mean(log(diag(Q_inv))))

# save scaling factor
write_rds(scaling_factor, "data/intermediate/scaling_factor.rds")
