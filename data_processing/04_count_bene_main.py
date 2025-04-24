import pandas as pd
import duckdb
import argparse
import logging

logging.basicConfig(filename='logs/prep_bene_county.out', level=logging.INFO)


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

def get_bene_zip_query(mbsf_denom_prefix):
    
    query = f"""
    WITH bene AS (
        SELECT
            bene_id,
            zip,
            year,
            race, 
            sex,
            year - yob as age
        FROM 
            '{mbsf_denom_prefix}_*.parquet'
        WHERE  
            race in ('1', '2') AND
            sex in ('1', '2')
        -- LIMIT 1e6
        )
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
        count(bene_id) as n_enrollees
    FROM 
        bene
    GROUP BY 
        zip,
        year,
        race,
        sex,
        age_grp
    """
    return query

def main(args):
    ## connect to duckdb
    conn = duckdb.connect()
    
    logging.info("## obtain beneficiary counts per zipcode ----")
    df = conn.execute(get_bene_zip_query(args.mbsf_denom_prefix)).fetchdf()
    logging.info(f"total number of enrollees in zipcodes: {df.n_enrollees.sum()}")

    logging.info("## aggregate to counties ----")
    zip_to_county = get_zip_to_county(args.zip_county_csv)
    logging.info(f"summarize w: {zip_to_county.w.describe()}")

    df.set_index(['zip'], inplace=True)
    zip_to_county.set_index(['zip'], inplace=True)
    #print(df.shape)
    df = df.join(zip_to_county, how = 'left')
    #print(df.shape)
    #print(df[df.w.isna()].shape)

    df['n_enrollees'] = df.n_enrollees * df.w
    df = df.groupby(['year', 'county', 'race', 'sex', 'age_grp'])['n_enrollees'].sum().reset_index()
    logging.info(f"total number of enrollees in counties: {df.n_enrollees.sum()}")

    logging.info(f"## saving in {args.output_file} ----")
    df.set_index(['county'], inplace=True)
    df.to_csv(args.output_file)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--mbsf_denom_prefix', 
                        type=str, 
                        default='data/symlinks/mbsf_medpar_denom/mbsf_medpar_denom')
    parser.add_argument('--zip_county_csv', 
                        type=str,
                        default='data/county/zip_county_2015.csv')
    parser.add_argument('--output_file',
                        type=str,
                        default='data/symlinks/scratch/bene_county_main.csv')
    args = parser.parse_args()

    main(args)
