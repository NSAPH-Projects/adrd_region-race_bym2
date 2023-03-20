## input

* Run all the scripts/notebooks in `/analysis` that begin with ` 01_` to get medicare input datasets

* Run the following code in this folder

```
wget https://www2.census.gov/geo/docs/reference/county_adjacency.txt
wget https://www2.census.gov/geo/tiger/TIGER2015/COUNTY/tl_2015_us_county.zip
unzip tl_2015_us_county.zip -d tl_2015_us_county
wget https://www2.census.gov/geo/tiger/TIGER2015/STATE/tl_2015_us_state.zip
unzip tl_2015_us_state.zip -d tl_2015_us_state
```
