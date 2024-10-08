
# This script can be used to take ICD codes that are copy and pasted from the CCW
# algorithms and get them properly formatted for a .yml file

library(stringr)

# function
process_icd <- function(input_string){
  
  # remove periods and newline characters
  cleaned_words <- str_remove_all(input_string, "[\\.\\n]")
  
  # Split the string on commas
  split_string <- unlist(strsplit(cleaned_words, ", "))
  
  # remove any white space around strings
  split_string <- str_trim(split_string)
  
  # Get quotes around each code
  quoted_words <- str_c('"', split_string, '"', sep = "") %>%
    str_c(collapse = ", ")
  
  return(cat(quoted_words))
  
}

#----------- use function

# make sure there isn't a comma after the last code in the vector!

ihd_icd9 <- "41000, 41001, 410.02, 410.10, 410.11, 410.12, 410.20, 410.21, 
41022, 41030, 410.31, 410.32, 410.40, 410.41, 410.42, 410.50, 
41051, 41052, 410.60, 410.61, 410.62, 410.70, 410.71, 410.72, 
41080, 41081, 410.82, 410.90, 410.91, 410.92, 411.0, 411.1, 411.81, 
41189, 412, 413.0, 413.1, 413.9, 414.00, 414.01, 414.02, 414.03, 
41404, 41405, 414.06, 414.07, 414.12, 414.2, 414.3, 414.4, 414.8, 414.9"

ami_icd10 <- "I21.01, I21.02, I21.09, I21.11, I21.19, I21.21, I21.29, I21.3, I21.4, 
        I21.9, I21.A1, I21.A9, I22.0, I22.1, I22.2, I22.8, I22.9"

afib_icd10 <- "I48.0, I48.1, I48.11, I48.19, I48.2, I48.20, I48.21, I48.91"

hf_icd10 <- "I09.81, I11.0, I13.0, I13.2, I50.1, I50.20, I50.21, I50.22, I50.23, 
I50.30, I50.31, I50.32, I50.33, I50.40, I50.41, I50.42, I50.43, I50.810, I50.811, 
I50.812, I50.813, I50.814, I50.82, I50.83, I50.84, I50.89, I50.9"

hypert_icd10 <- "H35.031, H35.032, H35.033, H35.039, I10, I11.0, I11.9, I12.0, 
      I12.9, I13.0, I13.10, I13.11, I13.2, I15.0, I15.1, I15.2, 
      I15.8, I15.9, I67.4, N26.2"

ihd_icd10 <- "I20.0, I20.1, I20.8, I20.9, I21.01, I21.02, I21.09, I21.11, I21.19, 
      I21.21, I21.29, I21.3, I21.4, I21.A1, I21.A9, I22.0, 
      I22.1, I22.2, I22.8, I22.9, I23.0, I23.1, I23.2, I23.3, I23.4, 
      I23.5, I23.6, I23.7, I23.8, I24.0, I24.1, I24.8, I24.9, I25.10, 
      I25.110, I25.111, I25.118, I25.119, I25.2, I25.3, I25.41, I25.42,
      I25.5, I25.6, I25.700, I25.701, I25.708, I25.709, 
      I25.710, I25.711, I25.718, I25.719, I25.720, I25.721, I25.728, I25.729, 
      I25.730, I25.731, I25.738, I25.739, I25.750, I25.751, I25.758, 
      I25.759, I25.760, I25.761, I25.768, I25.769, I25.790, I25.791, I25.798, 
      I25.799, I25.810, I25.811, I25.812, I25.82, I25.83, I25.84, I25.89, I25.9"

process_icd(ihd_icd9)
process_icd(ami_icd10)
process_icd(afib_icd10)
process_icd(hf_icd10)
process_icd(hypert_icd10)
process_icd(ihd_icd10)
