# race_inequalities-adrd-besag
Describe spatial race inequalities of ADRD hospitalizations

## Run

* `/data/county`

  - unzip the shapefile compressed files

* `/data/symlinks`

  - run the symlink commands in the README.md

* [analysis/01-adrd_prep_county_adj.Rmd](analysis/01-adrd_prep_county_adj.Rmd) maps adjacency, shapefile, outcome counts and beneficiary counts to the same set of counties
* [analysis/01-hosp_prep_county_adj.Rmd](analysis/01-hosp_prep_county_adj.Rmd) maps adjacency, shapefile, HOSPITALIZATIONS counts and beneficiary counts to the same set of counties

* [analysis/02-adrd_prep_ratios_df.Rmd](analysis/02-adrd_prep_ratios_df.Rmd) take outcome counts and beneficiary counts for each statum, into standardized ratios
* [analysis/02-hosp_prep_ratios_df.Rmd](analysis/02-hosp_prep_ratios_df.Rmd) take HOSPITALIZATION counts and beneficiary counts for each statum, into standardized ratios

## Docker container
```
docker pull jrnold/rstan
```
