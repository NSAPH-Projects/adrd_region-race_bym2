

```r
## load packages ----
library(tidyverse)
library(magrittr)
```


```r
####
# Download adjacency
####

## Import data ----
county_adj_df <- readr::read_delim(
    '../data/input/local/county_adjacency.txt',
    delim = "\t",
    escape_double = FALSE,
    col_names = c("name_i", "fips_i",
                  "name_j", "fips_j"),
    trim_ws = TRUE
)
```

```
## Rows: 22200 Columns: 4
## ── Column specification ───────────────────────────────────────────────────────────────────────────
## Delimiter: "\t"
## chr (4): name_i, fips_i, name_j, fips_j
## 
## ℹ Use `spec()` to retrieve the full column specification for this data.
## ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
```

```r
county_adj_df
```

```
## # A tibble: 22,200 × 4
##    name_i             fips_i name_j                fips_j
##    <chr>              <chr>  <chr>                 <chr> 
##  1 Autauga County, AL 01001  Autauga County, AL    01001 
##  2 <NA>               <NA>   Chilton County, AL    01021 
##  3 <NA>               <NA>   Dallas County, AL     01047 
##  4 <NA>               <NA>   Elmore County, AL     01051 
##  5 <NA>               <NA>   Lowndes County, AL    01085 
##  6 <NA>               <NA>   Montgomery County, AL 01101 
##  7 Baldwin County, AL 01003  Baldwin County, AL    01003 
##  8 <NA>               <NA>   Clarke County, AL     01025 
##  9 <NA>               <NA>   Escambia County, AL   01053 
## 10 <NA>               <NA>   Mobile County, AL     01097 
## # … with 22,190 more rows
```


```r
## Forward fill ----
county_adj_df <- zoo::na.locf(county_adj_df)

## Remove self loops and add state fips ----
county_adj_df <- county_adj_df %>%
    dplyr::filter(fips_i != fips_j) %>%
    dplyr::mutate(state_i = substr(fips_i, 1, 2),
                  state_j = substr(fips_j, 1, 2))

## Fix FIPS ----
## Bedford City got lumped together with Bedford county in CMF data
county_adj_df <- county_adj_df %>%
    dplyr::filter(fips_i != "51515",
                  fips_j != "51515")

## Now remove states/territories we won't use ----
county_adj_df <- dplyr::filter(county_adj_df,
                                  state_i %in% c("37"),
                                  state_j %in% c("37"))

county_adj_df
```

```
## # A tibble: 512 × 6
##    name_i               fips_i name_j                fips_j state_i state_j
##    <chr>                <chr>  <chr>                 <chr>  <chr>   <chr>  
##  1 Alamance County, NC  37001  Caswell County, NC    37033  37      37     
##  2 Alamance County, NC  37001  Chatham County, NC    37037  37      37     
##  3 Alamance County, NC  37001  Guilford County, NC   37081  37      37     
##  4 Alamance County, NC  37001  Orange County, NC     37135  37      37     
##  5 Alamance County, NC  37001  Randolph County, NC   37151  37      37     
##  6 Alamance County, NC  37001  Rockingham County, NC 37157  37      37     
##  7 Alexander County, NC 37003  Caldwell County, NC   37027  37      37     
##  8 Alexander County, NC 37003  Catawba County, NC    37035  37      37     
##  9 Alexander County, NC 37003  Iredell County, NC    37097  37      37     
## 10 Alexander County, NC 37003  Wilkes County, NC     37193  37      37     
## # … with 502 more rows
```


```r
####
# Create IDs and dummies
####

## Adding dummy FIPS ----
add_dummy_county_ids <- function(county_adj_df) {
  ## Just returns a County Adjacency matrix with two new columns -- each
  ## representing a dummy variable from 1:n_counties
  
  ## Sort by FIPS
  new_adj <- dplyr::arrange(county_adj_df, fips_i, fips_j)
  
  ## Make a dummy dictionary that with FIPS as the key and a dummy as value.
  dummies <- as.list(1:length(unique(new_adj$fips_i)))
  names(dummies) <- unique(new_adj$fips_i)
  
  ## Then make a dummy for node_i and node_j
  new_adj$dummy_i <-
    unlist(dummies[new_adj$fips_i], use.names = FALSE)
  new_adj$dummy_j <-
    unlist(dummies[new_adj$fips_j], use.names = FALSE)
  
  return(new_adj)
}

add_dummy_state_ids <- function(county_adj_df) {
  ## Just returns a County Adjacency matrix with two new columns -- each
  ## representing a dummy variable from 1:n_states
  
  ## Sort by FIPS
  new_adj <- dplyr::arrange(county_adj_df, fips_i, fips_j)
  
  ## Make a dummy dictionary that with FIPS as the key and a dummy as value.
  dummies <- as.list(1:length(unique(new_adj$state_i)))
  names(dummies) <- unique(new_adj$state_i)
  
  ## Then make a dummy for node_i and node_j
  new_adj$dummy_state_i <-
    unlist(dummies[new_adj$state_i], use.names = FALSE)
  new_adj$dummy_state_j <-
    unlist(dummies[new_adj$state_j], use.names = FALSE)
  
  return(new_adj)
}

county_adj_df <- add_dummy_county_ids(county_adj_df)
county_adj_df <- add_dummy_state_ids(county_adj_df)

county_adj_df
```

```
## # A tibble: 512 × 10
##    name_i          fips_i name_j fips_j state_i state_j dummy_i dummy_j dummy_state_i dummy_state_j
##    <chr>           <chr>  <chr>  <chr>  <chr>   <chr>     <int>   <int>         <int>         <int>
##  1 Alamance Count… 37001  Caswe… 37033  37      37            1      17             1             1
##  2 Alamance Count… 37001  Chath… 37037  37      37            1      19             1             1
##  3 Alamance Count… 37001  Guilf… 37081  37      37            1      41             1             1
##  4 Alamance Count… 37001  Orang… 37135  37      37            1      68             1             1
##  5 Alamance Count… 37001  Rando… 37151  37      37            1      76             1             1
##  6 Alamance Count… 37001  Rocki… 37157  37      37            1      79             1             1
##  7 Alexander Coun… 37003  Caldw… 37027  37      37            2      14             1             1
##  8 Alexander Coun… 37003  Cataw… 37035  37      37            2      18             1             1
##  9 Alexander Coun… 37003  Irede… 37097  37      37            2      49             1             1
## 10 Alexander Coun… 37003  Wilke… 37193  37      37            2      97             1             1
## # … with 502 more rows
```


```r
####
# Explode as n_counties x n_counties matrix
####

make_county_adj_matrix <- function(county_adj_df) {
    ## Converts a County Adjacency dataframe into a traditional adjacency matrix
    ## of size n_counties x n_counties with 1 representing neighbors.
    
    ## Number of neighbors
    num <- county_adj_df %>%
        dplyr::group_by(dummy_i) %>%
        dplyr::summarize(neighbors_i = dplyr::n()) %>%
        dplyr::pull(neighbors_i)
    
    ## List of neighbors
    adj <- county_adj_df$dummy_j
    
    ## Create an appropriately sized matrix
    n_nodes <- length(num)
    A <- matrix(0L, nrow = n_nodes, ncol = n_nodes)
    
    ## Loop through num and adj and assign 1 to neighbors
    start_ix <- end_ix <- 0
    for (node in seq_along(num)) {
        for (n_neigh in num[node]) {
            start_ix  <- end_ix + 1
            end_ix    <- end_ix + n_neigh
            
            neighbors <- adj[start_ix:end_ix]
            
            A[node, neighbors] <- 1L
        }
    }
    return(A)
}

county_adj_matrix <- make_county_adj_matrix(county_adj_df)

county_adj_matrix[1:10, 1:10]
```

```
##       [,1] [,2] [,3] [,4] [,5] [,6] [,7] [,8] [,9] [,10]
##  [1,]    0    0    0    0    0    0    0    0    0     0
##  [2,]    0    0    0    0    0    0    0    0    0     0
##  [3,]    0    0    0    0    1    0    0    0    0     0
##  [4,]    0    0    0    0    0    0    0    0    0     0
##  [5,]    0    0    1    0    0    0    0    0    0     0
##  [6,]    0    0    0    0    0    0    0    0    0     0
##  [7,]    0    0    0    0    0    0    0    0    0     0
##  [8,]    0    0    0    0    0    0    0    0    0     0
##  [9,]    0    0    0    0    0    0    0    0    0     0
## [10,]    0    0    0    0    0    0    0    0    0     0
```


```r
####
# Make sparse
####

make_county_adj_sparse_list <- function(adj_matrix) {
  ## This is taken from mbjoseph CARstan repo -- returns a sparse
  ## representation of an adjacency matrix in the format that Stan needs
  ## Number of neighbors
  D_sparse <- rowSums(adj_matrix)
  
  ## Kyle Foreman script -- undirected graph so second line removes dupes
  W_sparse <- which(adj_matrix == 1, arr.ind = TRUE)
  W_sparse <- W_sparse[W_sparse[, 1] < W_sparse[, 2], ]
  
  ## Get eigenvalues of D^(-.5) * W * D^(-.5) for determinant computations
  invsqrtD <- diag(1 / sqrt(D_sparse))
  quadformDAD <- invsqrtD %*% adj_matrix %*% invsqrtD
  lambdas <- eigen(quadformDAD)$values
  
  ## Number of edges
  W_n <- nrow(W_sparse)
  
  return(list(
    D_sparse = D_sparse,
    W_sparse = W_sparse,
    lambdas = lambdas,
    W_n = W_n
  ))
}

## Save a sparse adjacency representation (for Stan) ----
county_adj_sparse_list <- make_county_adj_sparse_list(county_adj_matrix)
names(county_adj_sparse_list)
```

```
## [1] "D_sparse" "W_sparse" "lambdas"  "W_n"
```


```r
####
# Obtain a table of county IDs
####

## Save a unique mapping of FIPS to state and county dummy codes ----
county_fips_df <- county_adj_df %>%
    dplyr::select(
        county_name = name_i,
        fipschar = fips_i,
        fips_st = state_i,
        c_idx = dummy_i,
        s_idx = dummy_state_i
    ) %>%
    dplyr::distinct() %>%
    dplyr::mutate(st_abbr = unlist(lapply(strsplit(county_name, split = ", "),
                                          function(x)
                                              x[[2]])))
county_fips_df
```

```
## # A tibble: 100 × 6
##    county_name          fipschar fips_st c_idx s_idx st_abbr
##    <chr>                <chr>    <chr>   <int> <int> <chr>  
##  1 Alamance County, NC  37001    37          1     1 NC     
##  2 Alexander County, NC 37003    37          2     1 NC     
##  3 Alleghany County, NC 37005    37          3     1 NC     
##  4 Anson County, NC     37007    37          4     1 NC     
##  5 Ashe County, NC      37009    37          5     1 NC     
##  6 Avery County, NC     37011    37          6     1 NC     
##  7 Beaufort County, NC  37013    37          7     1 NC     
##  8 Bertie County, NC    37015    37          8     1 NC     
##  9 Bladen County, NC    37017    37          9     1 NC     
## 10 Brunswick County, NC 37019    37         10     1 NC     
## # … with 90 more rows
```


```r
write_rds(county_adj_df, "../data/intermediate/county_adj_df.rds")
write_rds(county_adj_sparse_list, "../data/intermediate/county_adj_sparse_list.rds")
write_rds(county_fips_df, "../data/intermediate/county_fips_df.rds")
```

