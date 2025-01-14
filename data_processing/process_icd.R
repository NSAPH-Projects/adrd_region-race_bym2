
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

asthma_9 <- "493.00, 493.01, 493.02, 493.10, 
493.11, 493.12, 493.20, 493.21, 
493.22, 493.81, 493.82, 493.90, 
493.91, 493.92"

asthma_10 <- "J45.20, J45.21, J45.22, J45.30, J45.31, J45.32, J45.40, J45.41, J45.42, J45.50, J45.51, 
J45.52, J45.901, J45.902, J45.909, J45.990, J45.991, J45.998, J82.83"

copd_9 <- "490, 491.0, 491.1, 491.20, 491.21, 
491.22, 491.8, 491.9, 492.0, 492.8, 
494.0, 494.1, 496"
  
copd_10 <- "J40, J41.0, J41.1, J41.8, J42, J43.0, J43.1, J43.2, J43.8, J43.9, J44.0, J44.1, J44.9, J47.0, 
J47.1, J47.9"


process_icd(asthma_9)
process_icd(asthma_10)
process_icd(copd_9)
process_icd(copd_10)

