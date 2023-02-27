# %% [markdown]
# ## Prepare ADRD dataset

# %%
## Load packages ----
import numpy as np
import pandas as pd
import sshtunnel
import psycopg2 as pg
import os

import json
import sys

import seaborn as sns
import matplotlib.pyplot as plt

# %%
## read zip to county crosswalk ----
zip_to_county = pd.read_csv('../data/input/remote/zip_county_2010.csv')
zip_to_county = zip_to_county[['ZIP', 'COUNTY']]
zip_to_county = zip_to_county.rename(columns = {'ZIP':'zip', 'COUNTY':'county'})
zip_w = zip_to_county.groupby(['zip'])['county'].count().reset_index()
zip_w = zip_w.rename(columns = {'county':'w'})
zip_w['w'] = 1 / zip_w.w
zip_to_county = zip_to_county.merge(zip_w)
zip_to_county.w.describe()

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

# %% [markdown]
# ## Beneficiary counts

# %%
## year range of interest ----
years_ = [y_ for y_ in range(2000, 2019)]
years_.remove(2015) # not available in DORIEH as of Jan 2023 

## obtain beneficiary counts per zipcode ----

bene_zip_list = list()

for y_ in years_: 
    print(y_)
    
    ## Define query ----
    sql_query = f"""
    SELECT 
        zip,
        year,
        race, 
        sex,
        case 
            when age < 65 then '<65'
            when age >= 65 and age < 75 then '[65,75)'
            when age >= 75 and age < 85 then '[75,85)'
            when age >= 85 then '>85'
        end age_grp,
        count(*) as n_enrollees
    FROM 
        medicare.enrollments
        LEFT JOIN medicare.beneficiaries ON medicare.enrollments.bene_id = medicare.beneficiaries.bene_id
    WHERE 
        year in ('{y_}') AND 
        race in ('1', '2') AND
        sex in ('1', '2')
    GROUP BY 
        age_grp, 
        year, 
        zip, 
        race, 
        sex
    ;
    """
    ## Request query ----
    b = pd.read_sql_query(sql_query, connection, index_col = 'zip').reset_index()
    bene_zip_list.append(b)

# %%
## crosswalk to counties ----
bene_zip_df = pd.concat(bene_zip_list)
bene_county_df = bene_zip_df.merge(zip_to_county)
bene_county_df['n_enrollees'] = bene_county_df.n_enrollees * bene_county_df.w
bene_county_df = bene_county_df.groupby(['year', 'county', 'race', 'sex', 'age_grp'])['n_enrollees'].sum().reset_index()

# %%
## total number of enrollees in zipcodes ----
bene_zip_df.n_enrollees.sum()

# %%
## total number of enrollees in counties ----
bene_county_df.n_enrollees.sum()

# %% [markdown]
# ## Admission counts

# %%
## year range of interest ----
years_ = [y_ for y_ in range(2000, 2019)]
years_.remove(2015) # not available in DORIEH as of Jan 2023 

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
      race in ('1', '2') AND
      sex in ('1', '2')
    ;
    """
    ## Request query ----
    a = pd.read_sql_query(sql_query, connection, index_col = 'zip').reset_index()
    adm_zip_list.append(a)

# %%
adm_zip_df = pd.concat(adm_zip_list)
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
## crosswalk to counties ----
adm_county_df = adm_zip_df.merge(zip_to_county)
adm_county_df['n_adrd'] = adm_county_df.n_adrd * adm_county_df.w
adm_county_df = adm_county_df.groupby(['year', 'county', 'race', 'sex', 'age_grp'])['n_adrd'].sum().reset_index()

# %%
## total number of adrd admissions in zipcodes ----
adm_zip_df.n_adrd.sum()

# %%
## total number of adrd admissions in counties ----
adm_county_df.n_adrd.sum()

# %% [markdown]
# ## Adrd counts

# %%
## obtain rows for all combinations of county, year, race, sex and age_grp ----
## merge with enrollee and adrd counts
## there may be missing counts for a given combination
county_ = sorted(bene_county_df.county.unique())
year_ = sorted(bene_county_df.year.unique())
race_ = sorted(bene_county_df.race.unique())
sex_ = sorted(bene_county_df.sex.unique())
age_grp_ = sorted(bene_county_df.age_grp.unique())

# %%
adrd_county_df = pd.DataFrame({'county':county_}).merge(pd.DataFrame({'year':year_}), how = 'cross')
adrd_county_df = adrd_county_df.merge(pd.DataFrame({'race':race_}), how = 'cross')
adrd_county_df = adrd_county_df.merge(pd.DataFrame({'sex':sex_}), how = 'cross')
adrd_county_df = adrd_county_df.merge(pd.DataFrame({'age_grp':age_grp_}), how = 'cross')

# %%
adrd_county_df['state'] = [str(x)[0:2] for x in adrd_county_df.county]
adrd_county_df = adrd_county_df[adrd_county_df.state == '37']

# %%
adrd_county_df = adrd_county_df.merge(bene_county_df, how = 'left')
adrd_county_df = adrd_county_df.merge(adm_county_df, how = 'left')

# %%
## total number of counties in bene_county_df (resulting from crosswalk)----
len(county_)

# %%
## total number of counties in adrd_county_df (after filtering NC) ----
len(adrd_county_df.county.unique())

# %%
## total number of enrollees in adrd_county_df ----
adrd_county_df.n_enrollees.sum()

# %%
## total number of adrd admissions in adrd_county_df ----
adrd_county_df.n_adrd.sum()

# %%
## percentage of county-race-sex-age_grp combinations with missing enrollees (all years) ----
adrd_county_df.n_enrollees.isnull().mean()

# %%
## percentage of county-race-sex-age_grp combinations with missing adrd hospitalizations (all years) ----
adrd_county_df.n_adrd.isnull().mean()

# %%
## save adrd_county_df
adrd_county_df.to_csv("../data/input/adrd_county_df.csv", index=False)

# %%


# %%


# %%



