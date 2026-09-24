# The lint commit 34021b0 moved Plan logic into helpers and changed behaviour.
# The first group pins behaviour that is now restored to 7951e8e. The second
# group pins the changes that NEWS.md declares.

# ---- restored ----

test_that("run_one_with_data() evaluates every extra argument first", {
  p <- Plan$new(verbose = FALSE)
  p$add_analysis("a", fn = function(data, argset, ...) 1)

  expect_error(p$run_one_with_data(1, list(), 42))
})

test_that("run_one_with_data() evaluates data before the action function", {
  p <- Plan$new(verbose = FALSE)
  p$add_analysis("a", fn = function(data, argset) 1)

  expect_error(p$run_one_with_data(1, data = stop("forced")), "forced")
})

test_that("run_one_with_data() looks up fn_name again after the extras", {
  assign("fswap", function(data, argset, x) "first", envir = globalenv())
  on.exit(rm("fswap", envir = globalenv()), add = TRUE)
  p <- Plan$new(verbose = FALSE)
  p$add_analysis("s", fn_name = "fswap")

  result <- p$run_one_with_data(
    "s",
    list(),
    x = {
      assign("fswap", function(data, argset, x) "second", envir = globalenv())
      1
    }
  )
  expect_identical(result, "second")
})

test_that("run_one_with_data() resolves fn_name twice", {
  counter <- 0
  makeActiveBinding(
    "fact",
    function() {
      counter <<- counter + 1
      return(function(data, argset) "active")
    },
    globalenv()
  )
  on.exit(rm("fact", envir = globalenv()), add = TRUE)
  p <- Plan$new(verbose = FALSE)
  p$add_analysis("act", fn_name = "fact")
  counter <- 0

  expect_identical(p$run_one_with_data("act", list()), "active")
  expect_identical(counter, 4)
})

test_that("run_one_with_data() and run_one() return a visible value", {
  p <- Plan$new(verbose = FALSE)
  p$add_data("d", direct = 1)
  p$add_analysis("inv", fn = function(data, argset) invisible(7))

  expect_true(withVisible(p$run_one_with_data("inv", list()))$visible)
  expect_true(withVisible(p$run_one("inv"))$visible)
})

test_that("an analysis with both fn and fn_name fails as it did before", {
  p <- Plan$new(verbose = FALSE)
  p$add_data("d", direct = 1)
  p$add_analysis(
    "both",
    fn = function(data, argset) 1,
    fn_name = "plnr::test_action_fn"
  )

  expect_error(p$run_one("both"), "object 'num_args' not found")
})

test_that("add_analysis_from_df() checks the data frame for fn_name", {
  p <- Plan$new(verbose = FALSE)
  expect_warning(
    p$add_analysis_from_df(fn_name = "g", df = data.frame(fn_name = "f")),
    "Coercing LHS to a list"
  )

  expect_identical(names(p$analyses), "f")
  expect_null(p$analyses[["f"]][["fn_name"]])
})

test_that("get_data() reads each data source when it reaches it", {
  p <- Plan$new(verbose = FALSE)
  p$add_data("a", fn = function() {
    p$.__enclos_env__$private$data[[2]]$direct <- "changed"
    return(1)
  })
  p$add_data("b", direct = "original")

  expect_identical(p$get_data()[["b"]], "changed")
})

test_that("set_config() returns FALSE invisibly", {
  expect_identical(
    withVisible(set_config()),
    list(value = FALSE, visible = FALSE)
  )
})

test_that("initialize() returns use_foreach invisibly", {
  p <- Plan$new(verbose = FALSE)

  expect_identical(
    withVisible(p$initialize(use_foreach = FALSE)),
    list(value = FALSE, visible = FALSE)
  )
})

# ---- declared in NEWS.md ----

test_that("use_foreach = NULL with one worker does not load progressr", {
  skip_if_not_installed("progressr")
  if (isNamespaceLoaded("progressr")) {
    unloaded <- tryCatch(
      {
        unloadNamespace("progressr")
        TRUE
      },
      error = function(e) FALSE
    )
    skip_if_not(unloaded, "progressr is loaded and cannot be unloaded")
  }
  foreach::registerDoSEQ()
  p <- Plan$new(verbose = FALSE, use_foreach = NULL)
  p$add_data("d", direct = 1)
  p$add_analysis("a", fn = function(data, argset) 1)

  expect_identical(p$run_all(), list(1))
  expect_false(isNamespaceLoaded("progressr"))
})

test_that("get_argsets_as_dt() reads argset exactly, not by partial match", {
  p <- Plan$new(verbose = FALSE)
  p$analyses$a <- list(argsets = list(k = 1))

  expect_error(p$get_argsets_as_dt(), "argument is not a matrix")
})

test_that("errors that plnr raises carry no call", {
  p <- Plan$new(verbose = FALSE)
  p$add_data("d", direct = 1)
  p$add_analysis("x")
  err <- tryCatch(p$run_one("x"), error = identity)

  expect_identical(conditionMessage(err), "Both fn and fn_name are NULL")
  expect_null(conditionCall(err))
})

test_that("a data frame with no rows adds no argsets and no analyses", {
  empty <- data.frame(name = character(), k = numeric())
  p <- Plan$new(verbose = FALSE)
  p$add_argset_from_df(empty)
  p$add_analysis_from_df(fn_name = "plnr::test_action_fn", df = empty)

  expect_identical(p$analyses, list())
})

test_that("try_again() does not evaluate verbose after a first success", {
  expect_true(try_again(1, verbose = stop("forced")))
})

# ---- unchanged, pinned so that a change is visible ----

test_that("get_argsets_as_dt() on a plan with no analyses fails", {
  expect_error(
    suppressWarnings(Plan$new(verbose = FALSE)$get_argsets_as_dt())
  )
})
