
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

rmarkdown::render("./04_convergence.Rmd", 
                  output_dir = "./_knit")

md_filename <- "./_knit/04_convergence.md"
md_txt <- readLines(md_filename)
md_txt <- gsub(paste0(getwd(), "/_knit/"), "./", md_txt)
cat(md_txt, file=md_filename, sep="\n")

rmarkdown::render("./05-m0_pos_med.Rmd", 
                  output_dir = "./_knit")

md_filename <- "./_knit/05-m0_pos_med.md"
md_txt <- readLines(md_filename)
md_txt <- gsub(paste0(getwd(), "/_knit/"), "./", md_txt)
cat(md_txt, file=md_filename, sep="\n")

rmarkdown::render("./05-m1_pos_med.Rmd", 
                  output_dir = "./_knit")

md_filename <- "./_knit/05-m1_pos_med.md"
md_txt <- readLines(md_filename)
md_txt <- gsub(paste0(getwd(), "/_knit/"), "./", md_txt)
cat(md_txt, file=md_filename, sep="\n")

rmarkdown::render("./06-m0_pos_maps.Rmd", 
                  output_dir = "./_knit")

md_filename <- "./_knit/06-m0_pos_maps.md"
md_txt <- readLines(md_filename)
md_txt <- gsub(paste0(getwd(), "/_knit/"), "./", md_txt)
cat(md_txt, file=md_filename, sep="\n")
