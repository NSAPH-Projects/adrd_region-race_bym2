
## Set the working directory as the location of the _knit.R file (default rmarkdown and Rmd configurations)

## knit ----
rmarkdown::render("./_3_explore_num_enrollees.Rmd", 
                  output_dir = "./_knit")

md_filename <- "./_knit/_3_explore_num_enrollees.md"
md_txt <- readLines(md_filename)
md_txt <- gsub(paste0(getwd(), "/_knit/"), "./", md_txt)
cat(md_txt, file=md_filename, sep="\n")

rmarkdown::render("./_4_aggregate_adrd_hosp.Rmd", 
                  output_dir = "./_knit")

md_filename <- "./_knit/_4_aggregate_adrd_hosp.md"
md_txt <- readLines(md_filename)
md_txt <- gsub(paste0(getwd(), "/_knit/"), "./", md_txt)
cat(md_txt, file=md_filename, sep="\n")
