context("basic (support)")

test_that("basic progression parameters", {
  p <- basic_parameters_progression()
  expect_setequal(
    names(p),
    c("s_E", "s_asympt", "s_sympt", "s_hosp", "s_ICU", "s_rec",
      "gamma_E", "gamma_asympt", "gamma_sympt", "gamma_hosp",
      "gamma_ICU", "gamma_rec"))

  ## TODO: Lilith; you had said that there were some constraints
  ## evident in the fractional representation of these values - can
  ## you write tests here that reflect that?
})


test_that("basic_parameters returns a list of parameters", {
  date <- sircovid_date("2020-02-01")
  beta_date <- sircovid_date(c("2020-02-01", "2020-02-14", "2020-03-15"))
  beta_value <- c(3, 1, 2)

  p <- basic_parameters(date, "uk")
  expect_type(p, "list")
  expect_length(p$beta_step, 1)
  expect_identical(p$m, sircovid_transmission_matrix("uk"))

  progression <- basic_parameters_progression()
  expect_identical(p[names(progression)], progression)

  shared <- sircovid_parameters_shared(date, "uk", NULL, NULL)
  expect_identical(p[names(shared)], shared)
})


test_that("can tune the noise parameter", {
  p1 <- basic_parameters_observation(1e6)
  p2 <- basic_parameters_observation(1e4)
  expect_setequal(names(p1), names(p2))
  v <- setdiff(names(p1), "exp_noise")
  expect_mapequal(p1[v], p2[v])
  expect_equal(p1$exp_noise, 1e6) # default
  expect_equal(p2$exp_noise, 1e4) # given
})


test_that("basic_index identifies ICU and D_tot", {
  info <- list(index = list(I_ICU_tot = 3L, D_tot = 4L))
  expect_equal(basic_index(info), list(run = c(icu = 3L, deaths = 4L)))
})


test_that("basic_index identifies ICU and D_tot in real model", {
  date <- sircovid_date("2020-02-07")
  p <- basic_parameters(date, "england")
  mod <- basic$new(p, 0, 10)
  info <- mod$info()
  index <- basic_index(info)
  expect_equal(index$run[["icu"]], which(names(info$index) == "I_ICU_tot"))
  expect_equal(index$run[["deaths"]], which(names(info$index) == "D_tot"))

  mod$set_index(index$run)
  expect_equal(
    mod$run(date),
    matrix(0, 2, 10, dimnames = list(c("icu", "deaths"), NULL)))
})


test_that("basic compare function returns NULL if no data present", {
  state <- c(icu = 0, deaths = 0)
  prev_state <- c(icu = 0, deaths = 0)
  observed <- list(icu = NA, deaths = NA)
  pars <- basic_parameters(sircovid_date("2020-01-01"), "uk", exp_noise = Inf)
  expect_null(basic_compare(state, prev_state, observed, pars))
})


test_that("observation function correctly combines likelihoods", {
  state <- rbind(icu = 10:15, deaths = 1:6)
  prev_state <- matrix(1, 2, 6, dimnames = dimnames(state))
  observed1 <- list(icu = 13, deaths = NA)
  observed2 <- list(icu = NA, deaths = 3)
  observed3 <- list(icu = 13, deaths = 3)

  pars <- basic_parameters(sircovid_date("2020-01-01"), "uk", exp_noise = Inf)
  ll1 <- basic_compare(state, prev_state, observed1, pars)
  ll2 <- basic_compare(state, prev_state, observed2, pars)
  ll3 <- basic_compare(state, prev_state, observed3, pars)

  expect_length(ll3, 6)

  ll_itu <- ll_nbinom(observed3$icu, pars$observation$phi_ICU * state[1, ],
                      pars$observation$k_ICU, Inf)
  ll_deaths <- ll_nbinom(observed3$deaths,
                         pars$observation$phi_death * (state[2, ] - 1),
                         pars$observation$k_death, Inf)
  expect_equal(ll1, ll_itu)
  expect_equal(ll2, ll_deaths)
  expect_equal(ll3, ll1 + ll2)
})


test_that("can compute initial conditions", {
  p <- basic_parameters(sircovid_date("2020-02-07"), "england")
  mod <- basic$new(p, 0, 10)
  info <- mod$info()

  initial <- basic_initial(info, 10, p)
  expect_setequal(names(initial), c("state", "step"))
  expect_equal(initial$step, p$initial_step)

  initial_y <- mod$transform_variables(initial$state)
  expect_equal(initial_y$N_tot, sum(p$population))
  expect_equal(initial_y$S + drop(initial_y$I_asympt), p$population)
  expect_equal(drop(initial_y$I_asympt), append(rep(0, 16), 10, after = 3))

  remaining <- initial$state[-c(info$index$N_tot, info$index$S,
                                info$index$I_asympt)]
  expect_true(all(remaining == 0))
})
