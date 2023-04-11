

```r
## Load libraries ----
library(tidyverse)
library(magrittr)
library(sf)
library(cowplot)
library(viridis)
library(RColorBrewer)
```


```r
## Read data ----
stanfit_samples <- read_rds("../data/intermediate/m0-stanfit_samples.rds")
stanfit_summary <- read_rds("../data/intermediate/m0-stanfit_summary.rds")
county_sf <- read_rds("../data/intermediate/county_sf.rds")
pos_med <- read_rds("../data/intermediate/m0-pos_med.rds")

pos_med_sf <- county_sf %>% 
  select(county) %>% 
  right_join(pos_med)
```

```
## Joining, by = "county"
```

```r
dim(county_sf)
```

```
## [1] 3108   19
```

```r
dim(pos_med_sf)
```

```
## [1] 6216   19
```

```r
colnames(pos_med_sf)
```

```
##  [1] "county"          "geometry"        "race"            "person_years"    "expected"        "observed"       
##  [7] "black"           "log_expected"    "county_name"     "fipschar"        "fips_st"         "c_idx"          
## [13] "s_idx"           "st_abbr"         "y"               "pos_med_y"       "shared"          "shared_unscaled"
## [19] "specific"
```


```r
county_sf <- read_rds("../data/intermediate/county_sf.rds")
county_fips_df <- read_rds("../data/intermediate/county_fips_df.rds")
state_sf <- read_sf("../data/input/local/tl_2015_us_state/tl_2015_us_state.shp")
state_sf %<>% 
  left_join(
    county_sf %>% 
      left_join(county_fips_df) %>% 
      st_drop_geometry() %>% 
      distinct(STATEFP, s_idx, st_abbr)
  ) %>% 
  filter(!is.na(s_idx))
```

```
## Joining, by = "county"
## Joining, by = "STATEFP"
```


## Observed vs Predicted

### log ratios (y)


```r
pos_med_sf %>% 
  mutate(
    res = y - pos_med_y,
    res_is_out = if_else(abs(res) > 2/3, 1, 0) 
  ) %>% 
  ggplot() +
  geom_sf(aes(fill = exp(y), col = as.factor(res_is_out)), lwd = 0.2) +
  facet_grid(~race) +
  theme(legend.position = "bottom")
```

![](./06-m0_pos_maps_files/figure-html/unnamed-chunk-4-1.png)<!-- -->

### posterior median log ratios (pos_med_y)

In this model the "prediction" is a smoothed version of the observed.


```r
pos_med_sf %>% 
  ggplot() +
  geom_sf(aes(fill = pos_med_y), lwd = 0.00) +
  facet_grid(~race) +
  scale_fill_viridis(option = "D") + 
  theme_map() + 
  theme(legend.position = "bottom") 
```

![](./06-m0_pos_maps_files/figure-html/unnamed-chunk-5-1.png)<!-- -->

## Risk decomposition

## state effects


```r
param = rownames(stanfit_summary$summary)
nu = tibble(
  param = param[grep("nu", param)],
  med = stanfit_summary$summary[grep("nu", param),"50%"],
  s_idx = 1:length(grep("nu", param))
)

state_sf %>% 
  left_join(nu) %>% 
  ggplot() + 
  geom_sf(aes(fill = med))
```

```
## Joining, by = "s_idx"
```

![](./06-m0_pos_maps_files/figure-html/unnamed-chunk-6-1.png)<!-- -->

## shared unscaled


```r
summary(pos_med$shared_unscaled)
```

```
##       Min.    1st Qu.     Median       Mean    3rd Qu.       Max. 
## -1.3119758 -0.3005376  0.0118608 -0.0000618  0.2838894  2.4400892
```

```r
hist(pos_med$shared_unscaled)
```

![](./06-m0_pos_maps_files/figure-html/unnamed-chunk-7-1.png)<!-- -->


```r
summary(pos_med$specific)
```

```
##      Min.   1st Qu.    Median      Mean   3rd Qu.      Max. 
## -0.770834 -0.098017  0.014863  0.001183  0.106828  0.702880
```

```r
hist(pos_med$specific)
```

![](./06-m0_pos_maps_files/figure-html/unnamed-chunk-8-1.png)<!-- -->


```r
pos_med_sf %<>% 
  mutate(
    shared_unscaled_inliers = if_else(shared_unscaled > -1 & shared_unscaled < 1, 
                                      shared_unscaled, as.numeric(NA)),
    shared_unscaled_outliers = if_else(shared_unscaled <= -1 | shared_unscaled >= 1, 
                                       shared_unscaled, as.numeric(NA)),
    shared_unscaled_outliers = if_else(shared_unscaled_outliers <= -1, -1, shared_unscaled_outliers),
    shared_unscaled_outliers = if_else(shared_unscaled_outliers >= 1, 1, shared_unscaled_outliers)
  ) 

pos_med_sf %>% 
  st_drop_geometry() %>% 
  select(shared_unscaled, shared_unscaled_inliers, shared_unscaled_outliers)
```

```
## # A tibble: 6,216 × 3
##    shared_unscaled shared_unscaled_inliers shared_unscaled_outliers
##              <dbl>                   <dbl>                    <dbl>
##  1         -0.452                  -0.452                        NA
##  2         -0.452                  -0.452                        NA
##  3         -0.332                  -0.332                        NA
##  4         -0.332                  -0.332                        NA
##  5         -0.0331                 -0.0331                       NA
##  6         -0.0331                 -0.0331                       NA
##  7          0.118                   0.118                        NA
##  8          0.118                   0.118                        NA
##  9          0.0646                  0.0646                       NA
## 10          0.0646                  0.0646                       NA
## # … with 6,206 more rows
```


```r
filter(pos_med_sf, !is.na(shared_unscaled_outliers)) %>% 
  st_drop_geometry() %>% 
  select(shared_unscaled, shared_unscaled_inliers, shared_unscaled_outliers)
```

```
## # A tibble: 110 × 3
##    shared_unscaled shared_unscaled_inliers shared_unscaled_outliers
##              <dbl>                   <dbl>                    <dbl>
##  1            1.03                      NA                        1
##  2            1.03                      NA                        1
##  3            1.07                      NA                        1
##  4            1.07                      NA                        1
##  5           -1.07                      NA                       -1
##  6           -1.07                      NA                       -1
##  7            1.00                      NA                        1
##  8            1.00                      NA                        1
##  9            1.17                      NA                        1
## 10            1.17                      NA                        1
## # … with 100 more rows
```


```r
myPalette <- colorRampPalette(rev(RColorBrewer::brewer.pal(11, "Spectral")))
sc <- scale_fill_gradientn(colors = myPalette(100), 
                           limits = c(-1, 1))

p1 <- pos_med_sf %>% 
  filter(race == 1) %>% 
  ggplot() +
  geom_sf(aes(fill = specific), lwd = 0.0) + 
  theme_map() +
  labs(subtitle = "white specific") + 
  theme(legend.title = element_blank()) + 
  sc

p2 <- pos_med_sf %>% 
  filter(race == 1) %>% #shared_unscaled is non-race specific
  ggplot() +
  geom_sf(aes(fill = shared_unscaled_inliers), lwd = 0.0) + 
  geom_sf(data = filter(pos_med_sf, shared_unscaled_outliers == 1), color = "red", lwd = 0.5) + 
  geom_sf(data = filter(pos_med_sf, shared_unscaled_outliers == -1), color = "blue", lwd = 0.5) + 
  theme_map() + 
  labs(subtitle = "shared unscaled") + 
  sc

p3 <- pos_med_sf %>% 
  filter(race == 2) %>% 
  ggplot() +
  geom_sf(aes(fill = specific), lwd = 0.0) + 
  theme_map() + 
  labs(subtitle = "black specific") +
  sc
  
p <- cowplot::plot_grid(
  p1 + theme(legend.position = "none"), 
  p2 + theme(legend.position = "none"), 
  p3  + theme(legend.position = "none"),
  nrow = 3)

cowplot::plot_grid(
  p, 
  cowplot::get_legend(p1), 
  ncol = 2
)
```

![](./06-m0_pos_maps_files/figure-html/unnamed-chunk-11-1.png)<!-- -->


```r
filter(pos_med_sf, person_years == 0) %>% 
  st_drop_geometry() %>% 
  select(county, race, person_years, shared_unscaled, shared_unscaled_inliers, shared_unscaled_outliers)
```

```
## # A tibble: 83 × 6
##    county  race person_years shared_unscaled shared_unscaled_inliers shared_unscaled_outliers
##     <dbl> <dbl>        <int>           <dbl>                   <dbl>                    <dbl>
##  1  49033     2            0         -0.659                  -0.659                        NA
##  2  31181     2            0         -0.0752                 -0.0752                       NA
##  3  31015     2            0         -0.479                  -0.479                        NA
##  4   8017     2            0         -0.279                  -0.279                        NA
##  5  38085     2            0         -0.502                  -0.502                        NA
##  6  31017     2            0         -0.535                  -0.535                        NA
##  7  20075     2            0         -0.446                  -0.446                        NA
##  8  30059     2            0         -0.828                  -0.828                        NA
##  9   8111     2            0          0.776                   0.776                        NA
## 10  20101     2            0          0.555                   0.555                        NA
## # … with 73 more rows
```


```r
pos_med_sf %<>% 
  mutate(
    specific = if_else(person_years == 0, as.numeric(NA), specific),
    shared_unscaled_inliers = if_else(person_years == 0, as.numeric(NA), shared_unscaled_inliers),
    shared_unscaled_outliers = if_else(person_years == 0, as.numeric(NA), shared_unscaled_outliers)
  )
```


```r
myPalette <- colorRampPalette(rev(RColorBrewer::brewer.pal(11, "Spectral")))
sc <- scale_fill_gradientn(colors = myPalette(100), 
                           limits = c(-1, 1))

p1 <- pos_med_sf %>% 
  filter(race == 1) %>% 
  ggplot() +
  geom_sf(aes(fill = specific), lwd = 0.0) + 
  theme_map() +
  labs(subtitle = "white specific") + 
  theme(legend.title = element_blank()) + 
  sc

p2 <- pos_med_sf %>% 
  filter(race == 1) %>% #shared_unscaled is non-race specific
  ggplot() +
  geom_sf(aes(fill = shared_unscaled_inliers), lwd = 0.0) + 
  geom_sf(data = filter(pos_med_sf, shared_unscaled_outliers == 1), color = "red", lwd = 0.5) + 
  geom_sf(data = filter(pos_med_sf, shared_unscaled_outliers == -1), color = "blue", lwd = 0.5) + 
  theme_map() + 
  labs(subtitle = "shared unscaled") + 
  sc

p3 <- pos_med_sf %>% 
  filter(race == 2) %>% 
  ggplot() +
  geom_sf(aes(fill = specific), lwd = 0.0) + 
  theme_map() + 
  labs(subtitle = "black specific") +
  sc
  
p <- cowplot::plot_grid(
  p1 + theme(legend.position = "none"), 
  p2 + theme(legend.position = "none"), 
  p3  + theme(legend.position = "none"),
  nrow = 3)

cowplot::plot_grid(
  p, 
  cowplot::get_legend(p1), 
  ncol = 2
)
```

![](./06-m0_pos_maps_files/figure-html/unnamed-chunk-14-1.png)<!-- -->

## shared unscaled


```r
shared_ <- c(pos_med$shared, pos_med$specific)
myPalette <- colorRampPalette(rev(RColorBrewer::brewer.pal(11, "Spectral")))
sc <- scale_fill_gradientn(colors = myPalette(100), 
                           limits = c(min(shared_), max(shared_)))

p1 <- pos_med_sf %>% 
  filter(race == 1) %>% 
  ggplot() +
  geom_sf(aes(fill = specific), lwd = 0.00) + 
  theme_map() +
  labs(subtitle = "white specific") + 
  theme(legend.title = element_blank()) + 
  sc

p2 <- pos_med_sf %>% 
  filter(race == 1) %>% #shared_unscaled is non-race specific
  ggplot() +
  geom_sf(aes(fill = shared), lwd = 0.00) + 
  theme_map() + 
  labs(subtitle = "shared white") + 
  sc

p3 <- pos_med_sf %>% 
  filter(race == 2) %>% #shared_unscaled is non-race specific
  ggplot() +
  geom_sf(aes(fill = shared), lwd = 0.00) + 
  theme_map() + 
  labs(subtitle = "shared black") + 
  sc

p4 <- pos_med_sf %>% 
  filter(race == 2) %>% 
  ggplot() +
  geom_sf(aes(fill = specific), lwd = 0.00) + 
  theme_map() + 
  labs(subtitle = "black specific") +
  sc
  
p <- cowplot::plot_grid(
  p1 + theme(legend.position = "none"), 
  p2 + theme(legend.position = "none"), 
  p3  + theme(legend.position = "none"),
  p4  + theme(legend.position = "none"),
  nrow = 2, 
  ncol = 2)

cowplot::plot_grid(
  p, 
  cowplot::get_legend(p1), 
  ncol = 2, 
  rel_widths = c(0.8, 0.2)
)
```

![](./06-m0_pos_maps_files/figure-html/unnamed-chunk-15-1.png)<!-- -->
