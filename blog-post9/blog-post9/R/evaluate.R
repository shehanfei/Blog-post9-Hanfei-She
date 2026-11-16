# Out-of-sample forecast evaluation and investment performance.

# Out-of-sample R^2 relative to a benchmark forecast (Campbell-Thompson / Goyal-Welch):
# positive = beats the benchmark, negative = worse than the benchmark.
oos_r2 <- function(y, yhat, ybench) 1 - sum((y - yhat)^2) / sum((y - ybench)^2)

# Newey-West t-statistic for the mean of a series (handles autocorrelation in loss differences).
nw_tstat <- function(d, lag = 5) {
  n <- length(d); dm <- d - mean(d)
  v <- sum(dm^2) / n
  for (l in seq_len(lag)) v <- v + 2 * (1 - l / (lag + 1)) * sum(dm[(l + 1):n] * dm[1:(n - l)]) / n
  mean(d) / sqrt(v / n)
}

# Diebold-Mariano-style comparison: positive t = the model has smaller squared errors than the benchmark.
dm_test <- function(y, yhat, ybench) {
  d <- (y - ybench)^2 - (y - yhat)^2
  t <- nw_tstat(d)
  c(t = t, p_one_sided = 1 - pnorm(t))
}

forecast_metrics <- function(y, yhat, ybench) {
  dm <- dm_test(y, yhat, ybench)
  data.frame(OOS_R2_pct = 100 * oos_r2(y, yhat, ybench),
             RMSE = sqrt(mean((y - yhat)^2)),
             Hit_rate_pct = 100 * mean(sign(yhat) == sign(y)),
             DM_t = dm[["t"]], DM_p = dm[["p_one_sided"]])
}

# Strategy returns: position w (in [-1,1]) set at the close of day t earns the next day's return;
# pay `cost_bps` on every change in position.
strategy_returns <- function(w, r_simple, cost_bps = COST_BPS) {
  w_prev <- c(w[1], head(w, -1))
  w * r_simple - abs(w - w_prev) * cost_bps / 1e4
}

sharpe <- function(r) mean(r) / sd(r) * sqrt(252)

perf_stats <- function(r, w = NULL) {
  n <- length(r); wealth <- cumprod(1 + r)
  data.frame(Ann_return_pct = 100 * (wealth[n]^(252 / n) - 1),
             Ann_vol_pct = 100 * sd(r) * sqrt(252),
             Sharpe = sharpe(r),
             Max_drawdown_pct = 100 * min(wealth / cummax(wealth) - 1),
             Final_wealth = wealth[n],
             Switches_per_year = if (is.null(w)) NA_real_ else sum(diff(w) != 0) / n * 252)
}

# Moving-block bootstrap of the Sharpe-ratio difference between two return series.
boot_sharpe_diff <- function(r_a, r_b, B = 2000, block = 20) {
  n <- length(r_a); nb <- ceiling(n / block); out <- numeric(B)
  for (b in seq_len(B)) {
    starts <- sample.int(n, nb, replace = TRUE)
    idx <- ((rep(starts, each = block) + rep(0:(block - 1), times = nb) - 1) %% n) + 1
    idx <- idx[seq_len(n)]
    out[b] <- sharpe(r_a[idx]) - sharpe(r_b[idx])
  }
  out
}

# Average realized return within quintiles of the prediction (does ranking by prediction work?).
quintile_table <- function(y, yhat) {
  grp <- ceiling(5 * rank(yhat, ties.method = "first") / length(yhat))
  do.call(rbind, lapply(1:5, function(q) {
    v <- y[grp == q]
    data.frame(quintile = q, mean_ret = mean(v), se = sd(v) / sqrt(length(v)), n = length(v))
  }))
}
