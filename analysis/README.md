### Analysis scripts

[01-prep_county_adj.Rmd](01-prep_county_adj.Rmd)
* Maps adjacency, shapefile, outcome counts and beneficiary counts to the same set of counties
* Note: user chooses outcome (ADRD or non-ADRD) and main vs. sensitivity analysis


[02-prep_ratios_main.Rmd](02-prep_ratios_main.Rmd) and [02-prep_ratios_sensitivity.Rmd](02-prep_ratios_sensitivity.Rmd)
* Get basic stats/visualizations
* Get observed and expected counts in each county
* Note: for each script, user chooses outcome (ADRD or non-ADRD)


[03-calc_scaling_factor.R](03-calc_scaling_factor.R)
* Calculate scaling factor with INLA (needed for BYM2)


[04-run_stage1.R](04-run_stage1.R)
* Run model stage 1
* Note: user chooses outcome (ADRD or non-ADRD) and main vs. sensitivity analysis


[05-stage1_working_models.R](05-stage1_working_models.R)
* Choose stage 1 working models to store in working models folder


[06-run_stage2.R](06-run_stage2.R)
* Run model stage 2
* Note: user chooses outcome (ADRD or non-ADRD) and main vs. sensitivity analysis


[07-stage2_working_models.R](07-stage2_working_models.R)
* Choose stage 2 working models to store in working models folder


[08-convergence.Rmd](08-convergence.Rmd)
* Assess MCMC convergence for all models


[09-extract_results.Rmd](09-extract_results.Rmd)
* Extract results from Stan fit objects so they can be visualized in the next script
* Note: user chooses outcome (ADRD or non-ADRD) and main vs. sensitivity analysis


[10-one_model_maps_tables.Rmd](10-one_model_maps_tables.Rmd)
* All results that come from a single model


[11-across_outcomes.Rmd](11-across_outcomes.Rmd)
* Results comparing ADRD and non-ADRD outcomes
* Note: user chooses main vs. sensitivity analysis


[12-main_vs_sensitivity.Rmd](12-main_vs_sensitivity.Rmd)
* Results comparing main vs. sensitivity analysis

