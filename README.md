# Blog Post 9: Predicting Stock Returns with Gradient Boosting

Revisit the in-class stock-prediction experiment, explain why returns are hard to predict, try to improve the gradient boosting model, and evaluate out of sample against the original model and a simple benchmark, for both **forecast accuracy** and **investment performance**.

The post is `index.Rmd` (knits to `index.html`).

## What the analysis does

| Model | Description |
|---|---|
| Benchmark | Expanding historical-mean forecast (equivalent to buy-and-hold) |
| A. Original | Last 5 daily returns; xgboost with deep trees (depth 6, eta 0.3, 100 rounds); fit once on the training period |
| B. + Features | Adds momentum, volatility, moving-average gaps, RSI, drawdown, volume, VIX and Treasury-yield features |
| C. + Tuned and regularized | Shallow trees, small learning rate, subsampling, ridge penalty, number of rounds picked on a time-ordered validation set |
| D. + Walk-forward | Model C refit every 63 trading days on all past data (the final "improved" model) |

Evaluation: out-of-sample R² vs the historical mean, RMSE, hit rate, Diebold-Mariano-style test (Newey-West), cumulative squared-error advantage, prediction-quintile returns; then long/cash trading rules after transaction costs: annualized return, volatility, Sharpe ratio, max drawdown, turnover, moving-block bootstrap interval for the Sharpe difference vs buy-and-hold, and a cost-sensitivity table.

## Repository structure

```
blog-post9.Rproj    RStudio project (open this)
index.Rmd           the blog post; knits to index.html (GitHub Pages homepage)
R/config.R          ALL experiment settings (ticker, dates, original model, tuning grid, costs)
R/data.R            download + cache of prices
R/features.R        feature engineering (no look-ahead)
R/models.R          xgboost fitting, time-ordered tuning, walk-forward forecasting
R/evaluate.R        forecast metrics and investment performance
scripts/render.R    install-and-knit script
data/raw/           cached price CSVs (commit these so results are reproducible)
results/figures/    PNG figures        results/tables/  CSV tables
```

## Replication

Requirements: R >= 4.1 and packages `ggplot2`, `knitr`, `rmarkdown`, `xgboost`, `quantmod`, `zoo`.

1. Open `blog-post9.Rproj` in RStudio.
2. Click **Knit** on `index.Rmd` (or run `Rscript scripts/render.R` from the project root). The first knit downloads prices from Yahoo Finance into `data/raw/`; later knits reuse the cached files. Knitting takes a few minutes (walk-forward refits).
3. Outputs: `index.html`, `results/figures/*.png`, `results/tables/*.csv`.

**If the download fails** (no internet / Yahoo blocked), place CSV files with columns `date,adjusted,volume` in `data/raw/` named `SPY.csv`, `VIX.csv` and `TNX.csv`.

**To match the in-class experiment exactly**, edit `R/config.R` (ticker, start date, train/test split, number of lags, original hyperparameters) and re-knit; the text of the post updates from those settings.

## Linking RStudio and GitHub

1. Create an empty repo `blog-post9` on GitHub, then in RStudio choose File > New Project > Version Control > Git, paste the URL, and copy these files in; **or** open `blog-post9.Rproj` and run `usethis::use_git()` then `usethis::use_github()`.
2. Commit and push from the Git pane, including `index.html`, `data/raw/` and `results/`.
3. For the web page: Settings > Pages > Deploy from a branch > `main` / `(root)`.
