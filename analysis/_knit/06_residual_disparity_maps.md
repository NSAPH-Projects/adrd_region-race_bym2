

```r
## Load libraries ----
library(tidyverse)
library(magrittr)
library(sf)
```


```r
## Read data ----
pos_disparity <- read_rds('../data/intermediate/pos_disparity.rds')
county_sf <- read_sf("../data/input/local/tl_2022_us_county/tl_2022_us_county.shp")

dim(county_sf)
```

```
## [1] 3235   18
```

```r
names(county_sf)
```

```
##  [1] "STATEFP"  "COUNTYFP" "COUNTYNS" "GEOID"    "NAME"     "NAMELSAD" "LSAD"     "CLASSFP"  "MTFCC"    "CSAFP"   
## [11] "CBSAFP"   "METDIVFP" "FUNCSTAT" "ALAND"    "AWATER"   "INTPTLAT" "INTPTLON" "geometry"
```

Random effects of states explain prevalence, but are not components of disparity in the model. Should `nu` be replaced by `nu[1]` and `nu[2]`

## Total disparity


```r
pos_disparity_sf <- county_sf %>% 
  mutate(
    county = as.integer(GEOID)
  ) %>% 
  select(county) %>% 
  right_join(pos_disparity)
```

```
## Joining, by = "county"
```

```r
pos_disparity_sf %>% 
  ggplot() +
  geom_sf(aes(fill = total_disparity), lwd = 0.2) + 
  theme(legend.position = "bottom")
```

![](./06_residual_disparity_maps_files/figure-html/unnamed-chunk-3-1.png)<!-- -->

## Residual disparity


```r
pos_disparity_sf %>% 
  ggplot() +
  geom_sf(aes(fill = total_disparity), lwd = 0.2) + 
  theme(legend.position = "bottom")
```

![](./06_residual_disparity_maps_files/figure-html/unnamed-chunk-4-1.png)<!-- -->

## shared component disparity


```r
pos_disparity_sf %>% 
  mutate(
    shared = residual_disparity - specific
  ) %>% 
  ggplot() +
  geom_sf(aes(fill = shared), lwd = 0.2) + 
  theme(legend.position = "bottom")
```

![](./06_residual_disparity_maps_files/figure-html/unnamed-chunk-5-1.png)<!-- -->

## specific disparity


```r
pos_disparity_sf %>% 
  ggplot() +
  geom_sf(aes(fill = specific), lwd = 0.2) + 
  theme(legend.position = "bottom")
```

![](./06_residual_disparity_maps_files/figure-html/unnamed-chunk-6-1.png)<!-- -->
