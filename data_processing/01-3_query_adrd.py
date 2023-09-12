import numpy as np
import pandas as pd
import feather

import os
import json
import sys
import argparse

def main(args):
    print("## year range of interest ----")
    years_ = [y_ for y_ in range(2000, 2019)]
    years_.remove(2015) # inconsistent in DORIEH as of Apr 2023

    print("## Getting admission counts ----")
    ## obtain adrd counts per zipcode ----
    adm_zip_list = list()

    for y_ in years_:
        print(f"## {y_} ----")
        a = pd.read_feather(f"{args.input_prefix}_{y_}.feather")
        print(a.shape)
        adm_zip_list.append(a)
    #len(adm_zip_list)

    adm_zip_df = pd.concat(adm_zip_list)

    adm_zip_df['age'] = adm_zip_df.year - adm_zip_df.yob_
    adm_zip_df['age_grp'] = pd.cut(x=adm_zip_df['age'], 
                                   bins=[min(adm_zip_df.age), 65, 75, 85, max(adm_zip_df.age)],
                                   labels=['<65', '[65,75)', '[75,85)', '>85'])

    adm_zip_df = adm_zip_df.drop(columns='diagnoses')
    adm_zip_df = adm_zip_df.groupby(['year', 'zip', 'race', 'sex', 'age_grp'])['bene_id'].count().reset_index()
    adm_zip_df = adm_zip_df.rename(columns = {'bene_id':'n_adrd'})

    print("## Saving output ----")
    if args.output_format == "feather":
        adm_zip_df.to_feather(f"{args.output_prefix}.feather")
    elif args.output_format == "parquet":
        adm_zip_df.to_parquet(f"{args.output_prefix}.parquet")
    elif args.output_format == "csv":
        adm_zip_df.to_csv(f"{args.output_prefix}.csv", index=False)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--input_prefix", 
                        default = "../data/intermediate/scratch/adrd_adm"
                       )
    parser.add_argument("--output_format", 
                        default = "feather", 
                        choices=["parquet", "feather", "csv"]
                       )           
    parser.add_argument("--output_prefix", 
                    default = "../data/input/local/adm_zip_df"
                   )   
    args = parser.parse_args()
    main(args)
