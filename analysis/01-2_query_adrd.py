# %% [markdown]
# ## Prepare ADRD dataset
# query adrd is split in two because of memory usage (not ideal temporary solution)
# 148 GB at least are recommended 

# %%
## Load packages ----
import numpy as np
import pandas as pd
import feather

import sshtunnel
import psycopg2 as pg

import os
import json
import sys

# %%
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

# %%
## define functions ----
def get_outcomes(read_path):
    """ Get and return ICD codes """""
    f = open(read_path)
    res_dict = json.load(f)
    f.close()
    res_dict = json.loads(res_dict[0])
    return res_dict

def get_outcomes_set(outcome=None, year=None):
    """ Uses ICD9 for years prior 2015 and ICD10 otherwise """
    if year < 2015:
        outcomes_set = outcomes[outcome]["icd9"]
    elif year > 2015:
        outcomes_set = outcomes[outcome]["icd10"]
    else:
        outcomes_set = outcomes[outcome]["icd10"] + \
                       outcomes[outcome]["icd9"]
    return set(outcomes_set)

def get_outcome_in_diagnoses(outcomes_set=None, diagnoses=None):
    return any(o_ in outcomes_set for o_ in diagnoses)

# %%
## year range of interest ----
years_ = [y_ for y_ in range(2000, 2011)]
#years_.remove(2015) # not available in DORIEH as of Jan 2023

# %% [markdown]
# ## Admission counts

# %%
## obtain adrd counts per zipcode ----
adm_zip_list = list()

for y_ in years_: 
    print(y_)
    
    ## Define query ----
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
            year in ('{y_}')
    ) as adm
    ON bene.bene_id = adm.bene_id
    WHERE
      race in ('1', '2', '5') AND
      sex in ('1', '2')
    ;
    """
    ## Request query ----
    a = pd.read_sql_query(sql_query, connection, index_col = 'zip').reset_index()
    adm_zip_list.append(a)

# %%
len(adm_zip_list)

# %%
adm_zip_df = pd.concat(adm_zip_list)

# %%
adm_zip_df['age'] = adm_zip_df.year - adm_zip_df.yob_
adm_zip_df['age_grp'] = pd.cut(x=adm_zip_df['age'], 
                               bins=[min(adm_zip_df.age), 65, 75, 85, max(adm_zip_df.age)],
                               labels=['<65', '[65,75)', '[75,85)', '>85'])

## read outcomes ----
read_path = '../data/input/remote/icd_codes.json'
outcomes = get_outcomes(read_path)

## find diagnoses ----
for outcome in ['adrd']:
    adm_zip_df[outcome] = [get_outcome_in_diagnoses(get_outcomes_set(outcome, y_), d_[:1]) for y_, d_ in zip(adm_zip_df.year, adm_zip_df.diagnoses)]

# %%
adm_zip_df[['year', 'adrd']].groupby(['year']).sum()

# %%
keep = adm_zip_df[['adrd']].any(axis=1)
adm_zip_df = adm_zip_df[keep]
adm_zip_df = adm_zip_df.drop(columns='adrd')
adm_zip_df = adm_zip_df.groupby(['year', 'zip', 'race', 'sex', 'age_grp'])['bene_id'].count().reset_index()
adm_zip_df = adm_zip_df.rename(columns = {'bene_id':'n_adrd'})

# %%
#adm_zip_df.to_feather("../data/input/local/adm_zip_df_1.feather")
adm_zip_df.to_feather("../data/input/local/adm_zip_df_1_.feather")
