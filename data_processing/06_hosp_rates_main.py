#### note: need to run this file once for ADRD and once for non-ADRD

# python data_processing/202_adm_rates.py --admissions_county_csv data/symlinks/scratch/adrd_county.csv --output_file data/symlinks/scratch/adrd_rates.csv
# python data_processing/202_adm_rates.py --admissions_county_csv data/symlinks/scratch/hosp_county.csv --output_file data/symlinks/scratch/hosp_rates.csv

import pandas as pd
import argparse
import logging

logging.basicConfig(filename='logs/adm_rates.out', level=logging.INFO)

def main(args):

    logging.info("## read in data ----")
    bene_county_df = pd.read_csv(args.bene_county_csv)
    adm_county_df = pd.read_csv(args.admissions_county_csv)

    logging.info("## obtain admission rates per county ----")
    ## obtain rows for all combinations of county, year, race, sex and age_grp ----
    ## merge with enrollee and adrd counts
    ## there may be missing counts for a given combination
    county_ = sorted(bene_county_df.county.unique())
    year_ = sorted(bene_county_df.year.unique())
    race_ = sorted(bene_county_df.race.unique())
    sex_ = sorted(bene_county_df.sex.unique())
    age_grp_ = sorted(bene_county_df.age_grp.unique())

    adm_rates_df = pd.DataFrame({'county':county_}).merge(pd.DataFrame({'year':year_}), how = 'cross')
    adm_rates_df = adm_rates_df.merge(pd.DataFrame({'race':race_}), how = 'cross')
    adm_rates_df = adm_rates_df.merge(pd.DataFrame({'sex':sex_}), how = 'cross')
    adm_rates_df = adm_rates_df.merge(pd.DataFrame({'age_grp':age_grp_}), how = 'cross')
    # add state
    adm_rates_df['state'] = [int(float(x)/1000) for x in adm_rates_df.county]

    adm_rates_df = adm_rates_df.merge(bene_county_df, how = 'left')
    adm_rates_df = adm_rates_df.merge(adm_county_df, how = 'left')
    adm_rates_df

    logging.info("## there are county-years-race-sex-age_grps with zero enrollees ----")
    logging.info(adm_rates_df[adm_rates_df.n_enrollees.isnull()])

    logging.info("## total number of counties in bene_county_df (resulting from crosswalk)----")
    logging.info(len(county_))

    logging.info("## total number of counties in adm_rates_df ----")
    logging.info(len(adm_rates_df.county.unique()))

    logging.info("## total number of enrollee-years in adm_rates_df ----")
    logging.info(adm_rates_df.n_enrollees.sum())

    logging.info("## total number of adrd admissions in adm_rates_df ----")
    logging.info(adm_rates_df.n_admissions.sum())

    logging.info("## percentage of county-race-sex-age_grp combinations with missing enrollees (all years) ----")
    logging.info(adm_rates_df.n_enrollees.isnull().mean())

    logging.info("## percentage of county-race-sex-age_grp combinations with missing adrd hospitalizations (all years) ----")
    logging.info(f"adm_rates_df.n_admissions.isnull().mean() {adm_rates_df.n_admissions.isnull().mean()}")
    logging.info(f"(adm_rates_df.n_admissions == 0).mean() {(adm_rates_df.n_admissions == 0).mean()}")

    logging.info("## write to csv ----")
    adm_rates_df.to_csv(args.output_file, index = False)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--bene_county_csv',
                        type=str, 
                        default='data/symlinks/scratch/bene_county_main.csv')
    parser.add_argument('--admissions_county_csv', 
                        type=str,
                        default='data/symlinks/scratch/adrd_county_main.csv') # edit name here
    parser.add_argument('--output_file',
                        type=str,
                        default='data/symlinks/scratch/adrd_rates_main.csv') # edit name here
    args = parser.parse_args()

    logging.info(args)
    main(args)
