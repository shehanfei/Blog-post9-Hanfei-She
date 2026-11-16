# Feature engineering. Every feature at row t uses information available at the CLOSE of day t.
# The target at row t is the NEXT day's log return (in percent), so there is no look-ahead.

lagv <- function(x, k) if (k == 0) x else c(rep(NA, k), x[seq_len(length(x) - k)])

make_dataset <- function(px, vix = NULL, tnx = NULL, n_lags = 5) {
  px <- px[order(px$date), ]
  P <- px$adjusted
  lr <- c(NA, diff(log(P))) * 100                       # daily log return, percent
  d <- data.frame(date = px$date, price = P, ret = lr)

  # --- (1) the original predictors: the last n_lags daily returns (l0 = today)
  for (l in 0:(n_lags - 1)) d[[paste0("ret_l", l)]] <- lagv(lr, l)

  # --- (2) added predictors
  rs  <- function(k) zoo::rollsumr(lr, k, fill = NA)
  rsd <- function(k) zoo::rollapplyr(lr, k, sd, fill = NA)
  d$mom_5   <- rs(5);   d$mom_21 <- rs(21)               # momentum: cumulative return over k days
  d$mom_63  <- rs(63);  d$mom_126 <- rs(126)
  d$vol_5   <- rsd(5);  d$vol_21 <- rsd(21); d$vol_63 <- rsd(63)   # realized volatility
  d$vol_ratio <- d$vol_5 / d$vol_63
  d$ma_gap_50  <- 100 * log(P / zoo::rollmeanr(P, 50,  fill = NA))  # price relative to moving averages
  d$ma_gap_200 <- 100 * log(P / zoo::rollmeanr(P, 200, fill = NA))
  gain <- pmax(lr, 0); loss <- pmax(-lr, 0)
  d$rsi_14 <- 100 - 100 / (1 + zoo::rollmeanr(gain, 14, fill = NA) / zoo::rollmeanr(loss, 14, fill = NA))
  d$drawdown <- 100 * (P / zoo::rollmaxr(P, 252, fill = NA) - 1)    # distance from 1-year high
  if (!all(is.na(px$volume))) {
    v <- px$volume + 1
    d$volume_z <- log(v) - log(zoo::rollmeanr(v, 63, fill = NA))    # unusual trading volume
  }
  if (!is.null(vix)) {                                              # market-wide fear gauge
    v <- zoo::na.locf(vix$adjusted[match(px$date, vix$date)], na.rm = FALSE)
    d$vix <- log(v); d$vix_chg_5 <- d$vix - lagv(d$vix, 5)
  }
  if (!is.null(tnx)) {                                              # 10-year Treasury yield
    t <- zoo::na.locf(tnx$adjusted[match(px$date, tnx$date)], na.rm = FALSE)
    d$tnx <- t; d$tnx_chg_21 <- t - lagv(t, 21)
  }

  # --- target: next-day log return (percent)
  d$y <- c(lr[-1], NA)

  d[complete.cases(d), ]
}
