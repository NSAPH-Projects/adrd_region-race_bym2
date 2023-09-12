import numpy as np
import pandas as pd
import feather

import sshtunnel
import psycopg2 as pg

import os
import json
import sys
import argparse

## Open ssh tunnel to DB host ----
tunnel = sshtunnel.SSHTunnelForwarder(
    ('nsaph.rc.fas.harvard.edu', 22),
    ssh_username=f'{os.environ["MY_NSAPH_SSH_USERNAME"]}',
    ssh_private_key=f'{os.environ["HOME"]}/.ssh/id_rsa', 
    ssh_password=f'{os.environ["MY_NSAPH_SSH_PASSWORD"]}', 
    remote_bind_address=("localhost", 5432)
)

tunnel.start()

## Open connection to DB ----
connection = pg.connect(
    host='localhost',
    database='nsaph2',
    user=f'{os.environ["MY_NSAPH_DB_USERNAME"]}',
    password=f'{os.environ["MY_NSAPH_DB_PASSWORD"]}', 
    port=tunnel.local_bind_port
)

def read_icd_json(icd_json, outcome):
    with open(icd_json, 'r') as json_file:
        icd_dict = json.load(json_file)
    
    diag_string = (
        ",".join([f"'{x}'" for x in icd_dict[outcome]["icd9"]]) + 
        "," +
        ",".join([f"'{x}'" for x in icd_dict[outcome]["icd10"]])
    )

    return diag_string

def get_sql_query(year, diag_string):
    sql_query = f"""
    SELECT
        bene.bene_id,
        diagnoses,
        zip,
        year,
        race,
        sex, 
        EXTRACT(YEAR FROM dob) as yob_
    FROM 
        medicare.beneficiaries as bene
    RIGHT JOIN (
        SELECT 
            bene_id, 
            diagnoses, 
            zip, 
            year
        FROM 
            medicare.admissions as adm
        WHERE
            year in ('{year}') AND
            diagnoses && ARRAY[{diag_string}]
    ) as adm
    ON bene.bene_id = adm.bene_id
    WHERE
      race in ('1', '2', '5') AND
      sex in ('1', '2')
    ;
    """
    return sql_query
    
def main(args):
    diag_string = read_icd_json(args.icd_json, 'adrd')
    sql_query = get_sql_query(args.year, diag_string)
    adm = pd.read_sql_query(sql_query, connection)

    if args.output_format == "feather":
        adm.to_feather(f"{args.output_prefix}_{args.year}.feather")
    elif args.output_format == "parquet":
        adm.to_parquet(f"{args.output_prefix}_{args.year}.parquet")
    elif args.output_format == "csv":
        adm.to_csv(f"{args.output_prefix}_{args.year}.csv", index=False)

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--year", 
                        default = 2004, 
                        type=int
                       )
    parser.add_argument("--icd_json", 
                        default = "../data/input/remote/icd_codes.json"
                       )
    parser.add_argument("--output_format", 
                        default = "feather", 
                        choices=["parquet", "feather", "csv"]
                       )           
    parser.add_argument("--output_prefix", 
                    default = "../data/intermediate/scratch/adrd_adm"
                   )   
    args = parser.parse_args()
    main(args)
