# Download (and cache) daily prices. Cached CSVs in data/raw/ make the analysis reproducible
# even after Yahoo's history changes; delete a CSV to force a fresh download.
# Expected CSV columns if you supply your own file: date, adjusted, volume

fetch_symbol <- function(sym, start) {
  x <- quantmod::getSymbols(sym, src = "yahoo", from = start, auto.assign = FALSE)
  data.frame(date = as.Date(zoo::index(x)),
             adjusted = as.numeric(quantmod::Ad(x)),
             volume = if (quantmod::has.Vo(x)) as.numeric(quantmod::Vo(x)) else NA_real_)
}

load_symbol <- function(sym, start = DATA_START, dir = "data/raw") {
  path <- file.path(dir, paste0(gsub("[^A-Za-z0-9]", "", sym), ".csv"))
  if (file.exists(path)) {
    d <- read.csv(path, stringsAsFactors = FALSE)
    d$date <- as.Date(d$date)
    return(d)
  }
  d <- tryCatch(fetch_symbol(sym, start), error = function(e)
    stop("Could not download ", sym, " (", conditionMessage(e), "). ",
         "Put a CSV with columns date,adjusted,volume at ", path, " and re-run."))
  dir.create(dir, showWarnings = FALSE, recursive = TRUE)
  write.csv(d, path, row.names = FALSE)
  d
}
