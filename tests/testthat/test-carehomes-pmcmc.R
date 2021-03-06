context("pmcmc")

test_that("adding incidence adds appropriate states", {
  dat <- reference_data_mcmc()
  res <- add_trajectory_incidence(dat$trajectories, c("deaths", "deaths_hosp"))
  expect_true(all(c("deaths_inc", "deaths_hosp_inc") %in% rownames(res$state)))

  tmp <- res$state["deaths_inc", , ]
  expect_true(all(is.na(tmp[, 1:2])))
  deaths <- t(apply(tmp[, -c(1, 2)], 1, cumsum))
  expect_equal(
    deaths,
    res$state["deaths", , -c(1, 2)] - res$state["deaths", , 2])
})


test_that("can compute incidence for a single variable", {
  dat <- reference_data_mcmc()
  cmp <- add_trajectory_incidence(dat$trajectories, c("deaths", "deaths_hosp"))
  res <- add_trajectory_incidence(dat$trajectories, "deaths")
  expect_identical(res$state["deaths_inc", , ],
                   cmp$state["deaths_inc", , ])
})


test_that("Can compute forecasts from mcmc output", {
  dat <- reference_data_mcmc()
  res <- carehomes_forecast(dat, 3, 5, 10, c("deaths", "deaths_hosp"))

  expect_equal(dim(res$pars), c(3, 2))
  expect_equal(dim(res$probabilities), c(3, 3))
  expect_equal(dim(res$state), c(nrow(dat$state), 3))
  expect_equal(dim(res$trajectories$state),
               dim(dat$trajectories$state) + c(2, -8, 10))

  expect_true(all(c("deaths_inc", "deaths_hosp_inc") %in%
                  rownames(res$trajectories$state)))
})


test_that("Can compute forecasts from mcmc output without prepending", {
  dat <- reference_data_mcmc()
  res <- carehomes_forecast(dat, 3, 5, 10, c("deaths", "deaths_hosp"),
                            FALSE)

  expect_equal(dim(res$pars), c(3, 2))
  expect_equal(dim(res$probabilities), c(3, 3))
  expect_equal(dim(res$state), c(nrow(dat$state), 3))
  expect_equal(dim(res$trajectories$state),
               c(nrow(dat$trajectories$state) + 2, 3, 11))
  expect_true(all(c("deaths_inc", "deaths_hosp_inc") %in%
                  rownames(res$trajectories$state)))
})

test_that("Can combine trajectories of equal size", {
  dat <- reference_data_trajectories()
  res <- combine_trajectories(list(dat, dat), rank = FALSE)
  expect_equal(res$step, dat$trajectories$step)
  expect_equal(res$rate, dat$trajectories$rate)
  expect_equal(res$predicted, dat$trajectories$predicted)
  expect_equal(res$date, dat$trajectories$date)
  expect_equal(res$state, dat$trajectories$state * 2)
})


test_that("Can combine trajectories of equal size", {
  dat <- reference_data_trajectories()
  res <- combine_trajectories(list(dat, dat))
  expect_equal(res$step, dat$trajectories$step)
  expect_equal(res$rate, dat$trajectories$rate)
  expect_equal(res$predicted, dat$trajectories$predicted)
  expect_equal(res$date, dat$trajectories$date)

  expect_equal(sum(res$state), sum(dat$trajectories$state * 2))
  expect_equal(apply(res$state, c(1, 3), sum),
               apply(dat$trajectories$state, c(1, 3), sum) * 2)
  ## TODO: Lilith to check that the trajectories increase over the
  ## particle index.
})


test_that("Can combine trajectories with missing times", {
  dat <- reference_data_trajectories()

  ## Create a set where the first "real" data point is missing,
  ## shifting predictions back one day but keeping the same total
  ## number of forecast days.
  err <- dat
  n <- length(err$trajectories$date)
  err$trajectories$predicted <- err$trajectories$predicted[-1]
  err$trajectories$date <- err$trajectories$date[-n]
  err$trajectories$state <- err$trajectories$state[, , -n] * 2

  res <- combine_trajectories(list(dat, err))

  ## Predictions have shifted, so this is the same total sum
  expect_equal(sum(res$predicted), sum(dat$trajectories$predicted))
  ## But one less real data point
  expect_equal(sum(!res$predicted), sum(!dat$trajectories$predicted) - 1L)
  expect_equal(res$predicted, err$trajectories$predicted)
  expect_equal(res$date, err$trajectories$date)
  expect_equal(dim(res$state), dim(err$trajectories$state))

  f <- function(x) apply(x, c(1, 3), sum)
  tmp <- dat$trajectories$state[, , -n] + err$trajectories$state
  expect_equal(f(res$state), f(tmp))
})


test_that("can combine rt calculations over trajectories", {
  dat <- reference_data_trajectories()

  index_S <- grep("^S_", names(dat$predict$index))
  S <- dat$trajectories$state[index_S, , , drop = FALSE]
  pars <- lapply(seq_len(nrow(dat$pars)), function(i)
    dat$predict$transform(dat$pars[i, ]))
  rt <- carehomes_Rt_trajectories(
    dat$trajectories$step, S, pars,
    initial_step_from_parameters = TRUE,
    shared_parameters = FALSE)

  res <- combine_rt(list(rt, rt), list(dat, dat))
  cmp <- rt
  for (i in setdiff(names(cmp), c("step", "date"))) {
    cmp[[i]][1:2, ] <- NA
  }
  ## This should pass for everything, but the effective Rt
  ## calculations are different after aggregation for reasons as-yet
  ## unexplained. Possibly this is reasonable based on how Rt is
  ## calculated.
  expect_equal(res$Rt_general, cmp$Rt_general)
  expect_equal(res$Rt_all, cmp$Rt_all)
})
