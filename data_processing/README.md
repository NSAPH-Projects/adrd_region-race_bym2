[01_get_adrd_hosps.py](01_get_adrd_hosps.py)
* Identify hospitalizations with ICD diagnosis codes indicating ADRD


[02_reassign_adrd_hosps.R](02_reassign_adrd_hosps.R)
* Classify all hospitalizations as hospitalizations with vs. without ADRD in a more sophisticated way
* Load all hospitalizations and combine hospitalizations with same-day readmissions


[03_get_adrd_counts.py](03_get_adrd_counts.py) and [03_get_nonadrd_counts.py](03_get_nonadrd_counts.py)
* Store hospitalizations with and without ADRD


[04_count_bene_main.py](04_count_bene_main.py) and [04_count_bene_sensitivity.py](04_count_bene_sensitivity.py)
* Count number of beneficiaries per stratum in each county for main and sensitivity analyses
* Strata are race/age/sex for main analysis and race/age/sex/Medicaid eligibility for sensitivity analysis

  
