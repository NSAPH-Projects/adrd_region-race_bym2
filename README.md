# race_inequalities-adrd-besag
Describe spatial race inequalities of ADRD hospitalizations

## Run

* `/data/county`

  - unzip the shapefile compressed files

* `/data/symlinks`

  - run the symlink commands in the README.md

* `/analysis/1.1_prep_adj` maps adjacency, shapefile, outcome counts and beneficiary counts to the same set of counties
* `/analysis/1.2_prep_adj` maps adjacency, shapefile, HOSPITALIZATIONS counts and beneficiary counts to the same set of counties

* `/analysis/2.1_prep_adj` take outcome counts and beneficiary counts for each statum, into standardized ratios
* `/analysis/2.2_prep_adj` take HOSPITALIZATION counts and beneficiary counts for each statum, into standardized ratios

## Docker container
```
docker pull jrnold/rstan
```
