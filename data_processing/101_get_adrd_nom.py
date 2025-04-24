import pandas as pd
import duckdb
import argparse
import logging

def get_adrd_nom_query(mbsf_denom_prefix, medpar_denom_prefix, outcomes_prefix, year):
    query = f"""
    WITH adm AS (
        SELECT
            bene_id,
            adm_id,
            EXTRACT(YEAR FROM discharge_date) as year
        FROM
            '{medpar_denom_prefix}_{year}.parquet'
        WHERE
            adm_id in (
                SELECT adm_id
                FROM '{outcomes_prefix}adm_with_adrd_{year}.parquet'
            )
    )
    SELECT
        adm_id,
        bene_id,
        zip,
        year,
        race, 
        sex,
        year - yob as age,
        dual
    FROM
        '{mbsf_denom_prefix}_*.parquet'
    INNER JOIN
        adm
    USING
        (bene_id, year)
    WHERE  
        race in ('1', '2') AND
        sex in ('1', '2')  AND
        dual in (0, 1)
    """
    logging.info(query)
    return query

def main(args):
        
        conn = duckdb.connect()
        
        logging.info("## Preparing adrd nom ----")
        query = get_adrd_nom_query(
             args.mbsf_prefix,
             args.medpar_prefix,
             args.outcomes_prefix,
             args.year
        )

        df = conn.execute(query).fetchdf()
        logging.info("#print df shape and head")
        logging.info(df.shape)
        logging.info(df.head())
    
        logging.info("## Writing adrd nom ----")
        df = df.set_index(['adm_id'])
    
        output_file = f"{args.output_prefix}_{args.year}.{args.output_format}"
        if args.output_format == "parquet":
            df.to_parquet(output_file)
        elif args.output_format == "feather":
            df.to_feather(output_file)
        elif args.output_format == "csv":
            df.to_csv(output_file)
    
        logging.info(f"## Output file written to {output_file}")
        
        #close connection
        conn.close()

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--year", 
                        default = 2000, 
                        type=int
                       )
    parser.add_argument("--mbsf_prefix", 
                        default = "data/symlinks/mbsf_medpar_denom/mbsf_medpar_denom"
                       )
    parser.add_argument("--medpar_prefix", 
                        default = "data/symlinks/mbsf_medpar_denom/medpar_hospitalizations"
                       )
    parser.add_argument('--outcomes_prefix', 
                        type=str, 
                        default='data/symlinks/scratch/')
    parser.add_argument("--output_format", 
                        default = "parquet", 
                        choices=["parquet", "feather", "csv"]
                       )           
    parser.add_argument("--output_prefix", 
                    default = "data/symlinks/scratch/nom_adrd"
                   )
    args = parser.parse_args()


    logging.basicConfig(filename=f"logs/get_adrd_nom_{args.year}.out", level=logging.INFO)
    
    main(args)
