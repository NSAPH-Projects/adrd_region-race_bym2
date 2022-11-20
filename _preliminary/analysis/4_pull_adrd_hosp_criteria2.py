"""
Identifies diagnoses for population of interest 
"""

import json
import sys
import pandas as pd
import numpy as np

def get_outcomes(read_path):
    """ Get and return ICD codes """""
    f = open(read_path)
    res_dict = json.load(f)
    f.close()
    res_dict = json.loads(res_dict[0])
    return res_dict


def read_admissions(admissions_file, year):
    """ Reads MedPar dataset """
    cols = ["QID","RACE", "SSA_STATE_CD", "SSA_CNTY_CD", \
            "DIAG1","DIAG2","DIAG3","DIAG4","DIAG5","DIAG6","DIAG7",\
            "DIAG8","DIAG9","DIAG10"]
    df = pd.read_csv(admissions_file, usecols=cols)
    return df

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


def get_diags(admissions, diags=None, outcomes_set=None):
    """ Get True/False diagnosis for an outcome """
    return_col = pd.Series([False] * len(admissions))
    for col in diags:
        return_col = return_col | admissions[col].isin(outcomes_set)
    return return_col

read_path = '../data/input/icd_codes.json'
outcomes = get_outcomes(read_path)
diags = ["DIAG" + str(num) for num in np.arange(1, 11)]

admissions_list = []

for i in range(17):
    year = 2000 + i
    print(year)
    
    admissions_file = "../data/input/medpar/medpar2_" + str(year) + ".csv"
    admissions = read_admissions(admissions_file, year)
    
    # keep just admissions of population of interest
    states = set()
    states.add(34) #North Carolina SSA Code is 34
    admissions['in_state'] = admissions['SSA_STATE_CD'].isin(states)
    mask = admissions[['in_state']].any(axis=1)
    admissions = admissions[mask]

    # ADRD hospitalizations will be defined as any cause (first 10 ICD codes)
    admissions['adrd'] = get_diags(admissions, 
        diags=diags, outcomes_set=get_outcomes_set('adrd', year))

    # keep just the people with relevant diagnoses
    mask = admissions[['adrd']].any(axis=1)
    admissions = admissions[mask]

    # drop diag cols
    admissions = admissions.drop(columns=diags + ['in_state'])
    
    # create ssa5
    admissions['SSA5'] = [str(a) + str(b) for a,b in zip(admissions['SSA_STATE_CD'], admissions['SSA_CNTY_CD'])]
    
    # group and save
    admissions = admissions.groupby(['RACE', 'SSA5']).size().reset_index(name='counts')
    admissions['year'] = year
    admissions_list.append(admissions)

admissions = pd.concat(admissions_list)
admissions.to_csv("../data/intermediate/admissions.csv", index = False)
