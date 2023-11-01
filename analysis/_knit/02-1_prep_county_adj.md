

```r
## load packages ----
library(tidyverse)
library(magrittr)
library(sf)
```

In this notebook we make sure that the counties match in all three objects: the adjacency matrix, geometry and adrd data.


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
## ── Column specification ─────────────────────────────────────────────────────────────────────────────────────────
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
                                  !state_i %in% c("02","15", "66", "72", "60", "69", "78"),
                                  !state_j %in% c("02","15", "66", "72", "60", "69", "78"))

county_adj_df %<>% 
  mutate(county = as.numeric(fips_i))

county_adj_df
```

```
## # A tibble: 18,472 × 7
##    name_i             fips_i name_j                fips_j state_i state_j county
##    <chr>              <chr>  <chr>                 <chr>  <chr>   <chr>    <dbl>
##  1 Autauga County, AL 01001  Chilton County, AL    01021  01      01        1001
##  2 Autauga County, AL 01001  Dallas County, AL     01047  01      01        1001
##  3 Autauga County, AL 01001  Elmore County, AL     01051  01      01        1001
##  4 Autauga County, AL 01001  Lowndes County, AL    01085  01      01        1001
##  5 Autauga County, AL 01001  Montgomery County, AL 01101  01      01        1001
##  6 Baldwin County, AL 01003  Clarke County, AL     01025  01      01        1003
##  7 Baldwin County, AL 01003  Escambia County, AL   01053  01      01        1003
##  8 Baldwin County, AL 01003  Mobile County, AL     01097  01      01        1003
##  9 Baldwin County, AL 01003  Monroe County, AL     01099  01      01        1003
## 10 Baldwin County, AL 01003  Washington County, AL 01129  01      01        1003
## # … with 18,462 more rows
```


```r
## read county shp files
county_sf <- read_sf("../data/input/local/tl_2015_us_county/tl_2015_us_county.shp") %>%
  filter(!STATEFP %in% c("02","15", "66", "72", "60", "69", "78")) %>% 
  mutate(county = as.numeric(GEOID))

dim(county_sf)
```

```
## [1] 3108   19
```

```r
length(unique(county_adj_df$fips_i))
```

```
## [1] 3108
```

```r
length(unique(county_adj_df$fips_j))
```

```
## [1] 3108
```

```r
length(unique(county_adj_df$county))
```

```
## [1] 3108
```

```r
counties_adj_ = unique(county_adj_df$county)
counties_shp_ = unique(county_sf$county)

setdiff(counties_shp_, counties_adj_)
```

```
## [1] 46102
```

```r
setdiff(counties_adj_, counties_shp_)
```

```
## [1] 46113
```


```r
county_sf %>%
  st_simplify() %>%
  ggplot() +
  geom_sf() + 
  geom_sf(data = county_sf[!county_sf$county %in% counties_adj_, ], fill="blue")
```

![](./02-1_prep_county_adj_files/figure-html/unnamed-chunk-5-1.png)<!-- -->


```r
county_sf$county[county_sf$county == 46102] <- 46113 #Oglala Lakota County, SD. Shannon County, SD (FIPS code = 46113) was renamed Oglala Lakota County and assigned anew FIPS code (46102) effective in 2014

counties_adj_ = unique(county_adj_df$county)
counties_shp_ = unique(county_sf$county)

setdiff(counties_shp_, counties_adj_)
```

```
## numeric(0)
```

```r
setdiff(counties_adj_, counties_shp_)
```

```
## numeric(0)
```

```r
write_rds(county_sf, "../data/intermediate/county_sf.rds")
```


```r
adrd_county_df <- read_csv("../data/input/local/adrd_county_df.csv") %>% 
  filter(!state %in% c(2, 15, 66, 72, 60, 69, 78))
```

```
## Rows: 927648 Columns: 8
## ── Column specification ─────────────────────────────────────────────────────────────────────────────────────────
## Delimiter: ","
## chr (1): age_grp
## dbl (7): county, year, race, sex, state, n_enrollees, n_adrd
## 
## ℹ Use `spec()` to retrieve the full column specification for this data.
## ℹ Specify the column types or set `show_col_types = FALSE` to quiet this message.
```

```r
counties_adrd_ = unique(adrd_county_df$county)

length(counties_adrd_) #3109
```

```
## [1] 3109
```

```r
setdiff(counties_adrd_, counties_adj_) #51515 51560
```

```
## [1] 51515 51560
```

```r
setdiff(counties_adj_, counties_adrd_) #8014
```

```
## [1] 8014
```


```r
colorado_sf <- county_sf %>% 
  filter(STATEFP == "08") 

colorado_sf %>% 
  st_simplify() %>%
  ggplot() +
  geom_sf() + 
  geom_sf(data = colorado_sf[!colorado_sf$county %in% counties_adrd_, ], fill="blue")
```

![](./02-1_prep_county_adj_files/figure-html/unnamed-chunk-8-1.png)<!-- -->


```r
# county 8014 = CO,08,014,Broomfield County
# Broomfield county (FIPS 8014) is created out of parts of Adams, Boulder, Jefferson, and Weld counties. The Census Bureau estimates that the resulting population loss was 21,512 for Boulder, 15,870 for Adams, 1,726 for Jefferson, and 69 for Weld county.
xx <- adrd_county_df[adrd_county_df$county == 8013, ]
xx$county <- 8014
adrd_county_df <- rbind(adrd_county_df, xx)

adrd_county_df <- adrd_county_df[!adrd_county_df$county %in% c(51515, 51560), ]

counties_adrd_ = unique(adrd_county_df$county)

length(counties_adrd_)
```

```
## [1] 3108
```

```r
setdiff(counties_adrd_, counties_adj_)
```

```
## numeric(0)
```

```r
setdiff(counties_adj_, counties_adrd_)
```

```
## numeric(0)
```

```r
write_rds(adrd_county_df, "../data/intermediate/adrd_county_df.rds")
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
## # A tibble: 18,472 × 11
##    name_i             fips_i name_j     fips_j state_i state_j county dummy_i dummy_j dummy_state_i dummy_state_j
##    <chr>              <chr>  <chr>      <chr>  <chr>   <chr>    <dbl>   <int>   <int>         <int>         <int>
##  1 Autauga County, AL 01001  Chilton C… 01021  01      01        1001       1      11             1             1
##  2 Autauga County, AL 01001  Dallas Co… 01047  01      01        1001       1      24             1             1
##  3 Autauga County, AL 01001  Elmore Co… 01051  01      01        1001       1      26             1             1
##  4 Autauga County, AL 01001  Lowndes C… 01085  01      01        1001       1      43             1             1
##  5 Autauga County, AL 01001  Montgomer… 01101  01      01        1001       1      51             1             1
##  6 Baldwin County, AL 01003  Clarke Co… 01025  01      01        1003       2      13             1             1
##  7 Baldwin County, AL 01003  Escambia … 01053  01      01        1003       2      27             1             1
##  8 Baldwin County, AL 01003  Mobile Co… 01097  01      01        1003       2      49             1             1
##  9 Baldwin County, AL 01003  Monroe Co… 01099  01      01        1003       2      50             1             1
## 10 Baldwin County, AL 01003  Washingto… 01129  01      01        1003       2      65             1             1
## # … with 18,462 more rows
```


```r
####
# Obtain a table of county IDs
####

## Save a unique mapping of FIPS to state and county dummy codes ----
county_fips_df <- county_adj_df %>%
    dplyr::select(
        county_name = name_i,
        county = county, 
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
## # A tibble: 3,108 × 7
##    county_name         county fipschar fips_st c_idx s_idx st_abbr
##    <chr>                <dbl> <chr>    <chr>   <int> <int> <chr>  
##  1 Autauga County, AL    1001 01001    01          1     1 AL     
##  2 Baldwin County, AL    1003 01003    01          2     1 AL     
##  3 Barbour County, AL    1005 01005    01          3     1 AL     
##  4 Bibb County, AL       1007 01007    01          4     1 AL     
##  5 Blount County, AL     1009 01009    01          5     1 AL     
##  6 Bullock County, AL    1011 01011    01          6     1 AL     
##  7 Butler County, AL     1013 01013    01          7     1 AL     
##  8 Calhoun County, AL    1015 01015    01          8     1 AL     
##  9 Chambers County, AL   1017 01017    01          9     1 AL     
## 10 Cherokee County, AL   1019 01019    01         10     1 AL     
## # … with 3,098 more rows
```


```r
length(unique(county_fips_df$county))
```

```
## [1] 3108
```

```r
length(unique(adrd_county_df$county))
```

```
## [1] 3108
```


```r
## Save a sparse adjacency representation (for Stan) ----

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

county_adj_matrix <- make_county_adj_matrix(county_adj_df)
county_adj_sparse_list <- make_county_adj_sparse_list(county_adj_matrix)
names(county_adj_sparse_list)
```

```
## [1] "D_sparse" "W_sparse" "lambdas"  "W_n"
```


```r
# Use return_sparse_parts(A) for these next ones
D_sparse = county_adj_sparse_list$D_sparse
# neighbors per node
W_sparse = county_adj_sparse_list$W_sparse
# adjacent pairs
lambda = county_adj_sparse_list$lambdas
# eigenvalues
W_n = nrow(county_adj_sparse_list$W_sparse)
           
length(D_sparse)
```

```
## [1] 3108
```

```r
dim(W_sparse)
```

```
## [1] 9236    2
```

```r
length(lambda)
```

```
## [1] 3108
```

```r
W_n
```

```
## [1] 9236
```


```r
write_rds(county_adj_sparse_list, "../data/intermediate/county_adj_sparse_list.rds")
write_rds(county_fips_df, "../data/intermediate/county_fips_df.rds")
```
