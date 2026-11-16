# Gradient boosting helpers (xgboost). Targets are in percent so numbers are well scaled.

fit_xgb <- function(X, y, params, nrounds) {
  params$base_score <- mean(y)          # start from the training mean (a sensible "do nothing" forecast)
  params$nthread <- 1                   # single thread + seed = reproducible results
  params$seed <- SEED
  xgboost::xgb.train(params = params,
                     data = xgboost::xgb.DMatrix(as.matrix(X), label = y),
                     nrounds = nrounds, verbose = 0)
}

predict_xgb <- function(model, X, k = NULL) {
  if (is.null(k)) predict(model, as.matrix(X))
  else predict(model, as.matrix(X), iterationrange = c(1, k))
}

# Hyperparameter tuning that respects time order: fit on the first 80% of the TRAINING sample,
# score on the last 20%, for each grid cell and each number of boosting rounds.
tune_xgb <- function(train, features, grid = TUNE_GRID, max_rounds = TUNE_MAX_ROUNDS) {
  n <- nrow(train); n_fit <- floor(0.8 * n)
  fit <- train[seq_len(n_fit), ]; val <- train[(n_fit + 1):n, ]
  ks <- seq(20, max_rounds, by = 20)
  res <- list()
  for (g in seq_len(nrow(grid))) {
    p <- list(objective = "reg:squarederror", max_depth = grid$max_depth[g], eta = grid$eta[g],
              subsample = 0.7, colsample_bytree = 0.7, lambda = 5, min_child_weight = 20)
    m <- fit_xgb(fit[, features], fit$y, p, max_rounds)
    mse <- vapply(ks, function(k) mean((val$y - predict_xgb(m, val[, features], k))^2), numeric(1))
    res[[g]] <- data.frame(max_depth = grid$max_depth[g], eta = grid$eta[g],
                           nrounds = ks, val_mse = mse)
  }
  tab <- do.call(rbind, res)
  best <- tab[which.min(tab$val_mse), ]
  params <- list(objective = "reg:squarederror", max_depth = best$max_depth, eta = best$eta,
                 subsample = 0.7, colsample_bytree = 0.7, lambda = 5, min_child_weight = 20)
  list(params = params, nrounds = best$nrounds, table = tab, best = best,
       val_mse_mean = mean((val$y - mean(fit$y))^2))   # validation MSE of the "predict the mean" forecast
}

# Walk-forward (rolling-origin) forecasting: refit every `retrain_every` days on all data seen so far.
walk_forward <- function(df, features, params, nrounds, test_start,
                         retrain_every = RETRAIN_EVERY, window = NULL) {
  test_idx <- which(df$date >= test_start)
  preds <- rep(NA_real_, nrow(df))
  last <- tail(test_idx, 1)
  for (s in seq(test_idx[1], last, by = retrain_every)) {
    e <- min(s + retrain_every - 1, last)
    tr <- if (is.null(window)) seq_len(s - 1) else seq(max(1, s - window), s - 1)
    m <- fit_xgb(df[tr, features], df$y[tr], params, nrounds)
    preds[s:e] <- predict_xgb(m, df[s:e, features])
  }
  preds[test_idx]
}
