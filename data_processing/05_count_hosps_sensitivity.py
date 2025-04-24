import pandas as pd
import duckdb
import argparse
import logging

logging.basicConfig(filename='logs/prep_adm_county.out', level=logging.INFO)

def get_zip_to_county(zip_county_csv):
    zip_to_county = pd.read_csv(zip_county_csv, dtype = {'zip':str, 'county':str})
    #print(zip_to_county.shape)

    zip_w = zip_to_county.groupby(['zip'])['county'].count().reset_index()
    zip_w = zip_w.rename(columns = {'county':'w'})
    zip_w['w'] = 1 / zip_w.w
    #print(zip_w.shape)

    zip_to_county = zip_to_county.merge(zip_w)
    #print(zip_to_county.shape)

    return zip_to_county


def get_nom_query(nom_prefix):
    query = f"""
    SELECT 
        zip,
        year,
        race, 
        sex,
        dual,
        case 
            when age < 65 then '<65'
            when age >= 65 and age < 75 then '[65,75)'
            when age >= 75 and age < 85 then '[75,85)'
            when age >= 85 then '>85'
        end age_grp,
        count(adm_id) as n_admissions
    FROM 
        '{nom_prefix}_*.parquet'
    GROUP BY 
        zip,
        year,
        race,
        sex,
        age_grp,
        dual
    """
    return query
    
def main(args):
    ## connect to duckdb
    conn = duckdb.connect()
    
    logging.info("## obtain admission counts per zipcode ----")
    df = conn.execute(
        get_nom_query(args.nom_prefix)
        ).fetchdf()
    logging.info(f"total number of admissions in zipcodes: {df.n_admissions.sum()}")

    logging.info("## aggregate to counties ----")
    zip_to_county = get_zip_to_county(args.zip_county_csv)
    logging.info(f"summarize w: {zip_to_county.w.describe()}")

    df.set_index(['zip'], inplace=True)
    zip_to_county.set_index(['zip'], inplace=True)
    #print(df.shape)
    df = df.join(zip_to_county, how = 'left')
    #print(df.shape)
    #print(df[df.w.isna()].shape)

    df['n_admissions'] = df.n_admissions * df.w
    df = df.groupby(['year', 'county', 'race', 'sex', 'age_grp', 'dual'])['n_admissions'].sum().reset_index()
    logging.info(f"total number of admissions in counties: {df.n_admissions.sum()}")

    logging.info(f"## saving in {args.output_file} ----")
    df.set_index(['county'], inplace=True)
    df.to_csv(args.output_file)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--nom_prefix', 
                        type=str, 
                        default='data/symlinks/scratch/nom_hosp_dual') # edit name here
    parser.add_argument('--zip_county_csv', 
                        type=str,
                        default='data/county/zip_county_2015.csv')
    parser.add_argument('--output_file',
                        type=str,
                        default='data/symlinks/scratch/hosp_county_dual.csv') # edit name here
    args = parser.parse_args()

    logging.info(f"## args: {args}")
    main(args)

# python data_processing/201_adm_county.py --nom_prefix data/symlinks/scratch/nom_adrd --output_file data/symlinks/scratch/adrd_county.csv
# python data_processing/201_adm_county.py --nom_prefix data/symlinks/scratch/nom_hosp --output_file data/symlinks/scratch/hosp_county.csv
# python data_processing/201_adm_county.py --nom_prefix data/symlinks/scratch/nom_cvd --output_file data/symlinks/scratch/cvd_county.csv
