# run_all() has two execution paths: a for loop, and foreach. Both MUST return
# the same thing: a list that holds what each action function returned.

test_that("run_all() returns the action function values with foreach", {
  foreach::registerDoSEQ()

  p <- Plan$new(verbose = FALSE, use_foreach = TRUE)
  p$add_data(name = "d", direct = 1)
  p$add_analysis(name = "a", fn = function(data, argset) argset$x, x = "first")
  p$add_analysis(name = "b", fn = function(data, argset) argset$x, x = "second")

  expect_identical(p$run_all(), list("first", "second"))
})

test_that("run_all() returns the same list with and without foreach", {
  foreach::registerDoSEQ()

  p <- Plan$new(verbose = FALSE, use_foreach = FALSE)
  p$add_data(name = "d", direct = 1)
  p$add_analysis(name = "a", fn = function(data, argset) argset$x, x = 1)
  p$add_analysis(name = "b", fn = function(data, argset) argset$x, x = 2)
  sequential <- p$run_all()

  p$set_use_foreach(TRUE)
  expect_identical(p$run_all(), sequential)
})
