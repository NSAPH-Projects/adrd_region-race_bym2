
## Set the working directory as the location of the _knit.R file (default rmarkdown and Rmd configurations)

## knit ----
rmarkdown::render("./01_prep_adrd_ratios_df.Rmd", 
                  output_dir = "./_knit")

md_filename <- "./_knit/01_prep_adrd_ratios_df.md"
md_txt <- readLines(md_filename)
md_txt <- gsub(paste0(getwd(), "/_knit/"), "./", md_txt)
cat(md_txt, file=md_filename, sep="\n")

rmarkdown::render("./02_prep_county_adj.Rmd", 
                  output_dir = "./_knit")

md_filename <- "./_knit/02_prep_county_adj.md"
md_txt <- readLines(md_filename)
md_txt <- gsub(paste0(getwd(), "/_knit/"), "./", md_txt)
cat(md_txt, file=md_filename, sep="\n")

rmarkdown::render("./04_convergence.Rmd", 
                  output_dir = "./_knit")

md_filename <- "./_knit/04_convergence.md"
md_txt <- readLines(md_filename)
md_txt <- gsub(paste0(getwd(), "/_knit/"), "./", md_txt)
cat(md_txt, file=md_filename, sep="\n")

rmarkdown::render("./05_pos_med.Rmd", 
                  output_dir = "./_knit")

md_filename <- "./_knit/05_pos_med.md"
md_txt <- readLines(md_filename)
md_txt <- gsub(paste0(getwd(), "/_knit/"), "./", md_txt)
cat(md_txt, file=md_filename, sep="\n")

rmarkdown::render("./05_pos_med_maps.Rmd", 
                  output_dir = "./_knit")

md_filename <- "./_knit/05_pos_med_maps.md"
md_txt <- readLines(md_filename)
md_txt <- gsub(paste0(getwd(), "/_knit/"), "./", md_txt)
cat(md_txt, file=md_filename, sep="\n")

rmarkdown::render("./06_residual_disparity.Rmd", 
                  output_dir = "./_knit")

md_filename <- "./_knit/06_residual_disparity.md"
md_txt <- readLines(md_filename)
md_txt <- gsub(paste0(getwd(), "/_knit/"), "./", md_txt)
cat(md_txt, file=md_filename, sep="\n")

rmarkdown::render("./06_residual_disparity_maps.Rmd", 
                  output_dir = "./_knit")

md_filename <- "./_knit/06_residual_disparity_maps.md"
md_txt <- readLines(md_filename)
md_txt <- gsub(paste0(getwd(), "/_knit/"), "./", md_txt)
cat(md_txt, file=md_filename, sep="\n")
