# Install missing packages and knit the post. Run from the project root:
#   Rscript scripts/render.R
pkgs <- c("ggplot2", "knitr", "rmarkdown", "xgboost", "quantmod", "zoo")
missing <- pkgs[!pkgs %in% rownames(installed.packages())]
if (length(missing)) install.packages(missing, repos = "https://cloud.r-project.org")
rmarkdown::render("index.Rmd")   # writes index.html (the GitHub Pages homepage)
