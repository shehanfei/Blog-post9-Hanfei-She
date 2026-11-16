# All experiment settings live here, so the post and the README stay consistent.
# Edit this file (and re-knit) to match the in-class setup exactly.

TICKER     <- "SPY"                  # asset whose next-day return we predict
DATA_START <- "2000-01-01"           # first date downloaded
TEST_START <- as.Date("2019-01-01")  # everything before = training, everything from here = out-of-sample test
SEED       <- 9

# ---- ORIGINAL model: a plain gradient boosting model (xgboost defaults-style) ----
ORIG_LAGS    <- 5                    # predictors = the last 5 daily returns
ORIG_PARAMS  <- list(objective = "reg:squarederror", max_depth = 6, eta = 0.3)
ORIG_NROUNDS <- 100

# ---- IMPROVED model: tuning grid and retraining schedule ----
TUNE_GRID       <- expand.grid(max_depth = c(1, 2, 3), eta = c(0.01, 0.03))
TUNE_MAX_ROUNDS <- 600               # boosting rounds tried during tuning
RETRAIN_EVERY   <- 63                # trading days between refits in walk-forward (about 1 quarter)

# ---- Investment evaluation ----
COST_BPS <- 5                        # transaction cost per unit of position change, in basis points
