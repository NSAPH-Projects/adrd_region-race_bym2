[01_get_adrd_hosps.py](01_get_adrd_hosps.py)
* Identify hospitalizations with ICD diagnosis codes indicating ADRD


[02_reassign_adrd_hosps.R](02_reassign_adrd_hosps.R)
* Classify all hospitalizations as hospitalizations with vs. without ADRD in a more sophisticated way
*   Load all hospitalizations
*   Combine hospitalizations with same-day readmissions
*   Consider a hospitalization to be a hosp. with ADRD if the original hosp. or any of the subsequent same-day readmissions had a diagnosis code for ADRD


[03_get_adrd_hosps.py](03_get_adrd_hosps.py) and [03_get_nonadrd_hosps.py](03_get_nonadrd_hosps.py)
* Store hospitalizations with and without ADRD


[04_count_bene_main.py](04_count_bene_main.py) and [04_count_bene_sensitivity.py](04_count_bene_sensitivity.py)
* Count number of beneficiaries per stratum in each county for main and sensitivity analyses
* Strata are year/race/age group/sex for main analysis and year/race/age group/sex/Medicaid eligibility for sensitivity analysis

  
[05_count_hosps_main.py](05_count_hosps_main.py) and [05_count_hosps_sensitivity.py](05_count_hosps_sensitivity.py)
* Count number of hospitalizations with and without ADRD per stratum in each county for main and sensitivity analyses
* Strata are year/race/age group/sex for main analysis and year/race/age group/sex/Medicaid eligibility for sensitivity analysis
* Note: need to run each script once for ADRD and once for non-ADRD


[06_hosp_rates_main.py](06_hosp_rates_main.py) and [06_hosp_rates_sensitivity.py](06_hosp_rates_sensitivity.py)
*  Get rates of hospitalization with and without ADRD
*  Note: need to run each script once for ADRD and once for non-ADRD
