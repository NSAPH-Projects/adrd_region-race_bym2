
## Set the working directory as the location of the _knit.R file (default rmarkdown and Rmd configurations)

## knit ----
rmarkdown::render("./3_eda_enrollees_years1.Rmd", 
                  output_dir = "./_knit")

md_filename <- "./_knit/3_eda_enrollees_years1.md"
md_txt <- readLines(md_filename)
md_txt <- gsub(paste0(getwd(), "/_knit/"), "./", md_txt)
cat(md_txt, file=md_filename, sep="\n")

rmarkdown::render("./3_eda_enrollees_years2.Rmd", 
                  output_dir = "./_knit")

md_filename <- "./_knit/3_eda_enrollees_years2.md"
md_txt <- readLines(md_filename)
md_txt <- gsub(paste0(getwd(), "/_knit/"), "./", md_txt)
cat(md_txt, file=md_filename, sep="\n")

rmarkdown::render("./5_eda_adrd_hosp_criteria1.Rmd", 
                  output_dir = "./_knit")

md_filename <- "./5_eda_adrd_hosp_criteria1.md"
md_txt <- readLines(md_filename)
md_txt <- gsub(paste0(getwd(), "/_knit/"), "./", md_txt)
cat(md_txt, file=md_filename, sep="\n")

rmarkdown::render("./5_eda_adrd_hosp_criteria2.Rmd", 
                  output_dir = "./_knit")

md_filename <- "./5_eda_adrd_hosp_criteria2.md"
md_txt <- readLines(md_filename)
md_txt <- gsub(paste0(getwd(), "/_knit/"), "./", md_txt)
cat(md_txt, file=md_filename, sep="\n")

rmarkdown::render("./6_get_rates_criteria1.Rmd", 
                  output_dir = "./_knit")

md_filename <- "./6_get_rates_criteria1.Rmd"
md_txt <- readLines(md_filename)
md_txt <- gsub(paste0(getwd(), "/_knit/"), "./", md_txt)
cat(md_txt, file=md_filename, sep="\n")

rmarkdown::render("./6_get_rates_criteria2.Rmd", 
                  output_dir = "./_knit")

md_filename <- "./6_get_rates_criteria2.Rmd"
md_txt <- readLines(md_filename)
md_txt <- gsub(paste0(getwd(), "/_knit/"), "./", md_txt)
cat(md_txt, file=md_filename, sep="\n")

