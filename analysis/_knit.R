
## Set the working directory as the location of the _knit.R file (default rmarkdown and Rmd configurations)

## knit ----
rmarkdown::render("./02-1_prep_county_adj.Rmd", 
                  output_dir = "./_knit")

md_filename <- "./_knit/02-1_prep_county_adj.md"
md_txt <- readLines(md_filename)
md_txt <- gsub(paste0(getwd(), "/_knit/"), "./", md_txt)
cat(md_txt, file=md_filename, sep="\n")

rmarkdown::render("./02-2_prep_adrd_ratios_df.Rmd", 
                  output_dir = "./_knit")

md_filename <- "./_knit/02-2_prep_adrd_ratios_df.md"
md_txt <- readLines(md_filename)
md_txt <- gsub(paste0(getwd(), "/_knit/"), "./", md_txt)
cat(md_txt, file=md_filename, sep="\n")
