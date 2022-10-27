import wget
from zipfile import ZipFile
import os

## download counties shapefile from census-tiger site
url = 'https://www2.census.gov/geo/tiger/TIGER2022/COUNTY/tl_2022_us_county.zip'
wget.download(url, (''))
ZipFile('tl_2022_us_county.zip', 'r').extractall('data/input/scratch/tl_2022_us_county/')
os.system('rm tl_2022_us_county.zip')

## download zcta shapefile from census-tiger site
url = 'https://www2.census.gov/geo/tiger/TIGER2022/ZCTA520/tl_2022_us_zcta520.zip'
wget.download(url, (''))
ZipFile('tl_2022_us_zcta520.zip', 'r').extractall('data/input/scratch/tl_2022_us_zcta520/')
os.system('rm tl_2022_us_county.zip')
