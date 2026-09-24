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

# run_all_with_data() read .plnr.options from `...` but then looked for
# chunk_size at the top level of `...`, so chunk_size never reached foreach.
# It also passed .plnr.options on to the action function.

test_that("run_all() gives .plnr.options chunk_size to foreach", {
  seen <- "not called"
  foreach::setDoPar(
    fun = function(obj, expr, envir, data) {
      seen <<- obj$options$future$chunk.size
      return(do.call(foreach::`%do%`, list(obj, expr), envir = envir))
    },
    data = NULL,
    info = function(data, item) NULL
  )
  on.exit(foreach::registerDoSEQ(), add = TRUE)

  p <- Plan$new(verbose = FALSE, use_foreach = TRUE)
  p$add_data(name = "d", direct = 1)
  p$add_analysis(name = "a", fn = function(data, argset) "done")

  expect_identical(
    p$run_all(.plnr.options = list(chunk_size = 5)),
    list("done")
  )
  expect_identical(seen, 5)
})

test_that("run_all() does not pass .plnr.options to the action function", {
  p <- Plan$new(verbose = FALSE, use_foreach = FALSE)
  p$add_data(name = "d", direct = 1)
  p$add_analysis(name = "a", fn = function(data, argset, ...) list(...))

  expect_identical(
    p$run_all(extra = 2, .plnr.options = list(chunk_size = 5)),
    list(list(extra = 2))
  )
})
