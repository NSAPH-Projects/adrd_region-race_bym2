
# run this after script 100, which identifies the hosps that have ADRD codes
# run this before 101 and 102
# in 101, modify the "where" statement at the top to consider only adm_ids identified here
# in 102, add a "where" statement at the top to consider only adm_ids identified here

library(arrow)
library(data.table)
library(ggplot2)
library(lubridate)


#----- load all hospitalizations -----#

dir_hosp <- "data/symlinks/mbsf_medpar_denom/"
hosp_cols <- c("bene_id", "year", "adm_id", "admission_date", "discharge_date")

# load hospitalizations
hosp_list <- list()
cat("Loading hospitalization files \n")
for (y in as.character(2000:2018)) {
  cat(y, " ")
  f <- paste0(dir_hosp, "medpar_hospitalizations_", y, ".parquet")
  hosp_list[[y]] <- as.data.table(read_parquet(f, col_select = all_of(hosp_cols)))
}

# get into a single data.table with a column for year
dt <- rbindlist(hosp_list)
rm(hosp_list); gc()


#----- identify hospitalizations with ADRD -----#

dir_scratch <- "data/symlinks/scratch/"

# load admission IDs with ADRD codes
adm_adrd_list <- list()
cat("Loading ADRD admission ID files \n")
for (y in as.character(2000:2018)) {
  cat(y, " ")
  f <- paste0(dir_scratch, "outcomes_adrd_", y, ".parquet")
  adm_adrd_list[[y]] <- as.data.table(read_parquet(f))$adm_id
}

# unlist across years
adm_adrd <- unlist(adm_adrd_list, use.names = FALSE)


# identify hospitalizations with ADRD in hospitalization data -----#
dt[, adrd := as.integer(adm_id %in% adm_adrd)]
rm(adm_adrd_list, adm_adrd); gc()


#----- random sample for now! -----#

# set.seed(17)
# ids <- sample(unique(dt[,bene_id]), 100000)
# dt <- dt[bene_id %in% ids]
# gc()


#---------- identify same-day re-admissions ----------#

# sort by ID and admission date before getting lag column
setorder(dt, bene_id, admission_date)

# for each hospitalization, get the date of the previous discharge
dt[, prev_discharge_date := shift(discharge_date, type = "lag"), by = bene_id]

# does prev_discharge_date match current admission_date?
dt[, initial_or_readmit := fifelse(prev_discharge_date == admission_date, "SDR", "I")]
dt[, initial_or_readmit := fifelse(is.na(initial_or_readmit), "I", initial_or_readmit)] # make NAs I

# get a column that is like adm_id, but the IDs are the same if it's a same-day readmission
dt[, hosp_event_id := cumsum(initial_or_readmit != "SDR")]

# do any same-day readmissions have an ADRD code?
dt[, any_sdr_adrd := any(initial_or_readmit == "SDR" & adrd == 1), by = hosp_event_id]


#---------- re-assign initial hosp adrd codes ----------#

# remove same-day readmissions
dt <- dt[initial_or_readmit == "I"]

# get updated column for adrd hosps, including hosps with any ADRD codes in same-day readmissions
dt[, adrd_updated := as.integer(adrd == 1 | any_sdr_adrd)]

# save adm_ids for hospitalizations with ADRD
hosp_w_adrd <- dt[adrd_updated == 1, ]
cat("# of hosps with ADRD: ", nrow(hosp_w_adrd))
for (y in as.integer(unique(hosp_w_adrd$year))) {
  file_name <- paste0(dir_scratch, "adm_with_adrd_", y, ".parquet")
  ids <- hosp_w_adrd[year == as.integer(y), ]
  write_parquet(ids, file_name)
}

# save adm_ids for hospitalizations without ADRD
hosp_wo_adrd <- dt[adrd_updated == 0, ]
cat("# of hosps without ADRD: ", nrow(hosp_wo_adrd))
for (y in as.integer(unique(hosp_wo_adrd$year))) {
  file_name <- paste0(dir_scratch, "adm_without_adrd_", y, ".parquet")
  ids <- hosp_wo_adrd[year == as.integer(y), ]
  write_parquet(ids, file_name)
}

