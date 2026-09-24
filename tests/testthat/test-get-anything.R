# get_anything() once called get(x) from inside the plnr namespace. A plnr
# function, or an export of a package that plnr imports, then won over a user's
# function with the same name. A function defined anywhere except the global
# environment was not found at all.

test_that("a global function wins over a plnr internal with the same name", {
  assign(
    "hash_it",
    function(data, argset) "the user's hash_it",
    envir = globalenv()
  )
  on.exit(rm("hash_it", envir = globalenv()), add = TRUE)

  p <- Plan$new(verbose = FALSE)
  p$add_data(name = "d", direct = 1)
  p$add_analysis(name = "a", fn_name = "hash_it")

  expect_identical(p$run_one("a"), "the user's hash_it")
})

test_that("a global function wins over an export that plnr imports", {
  assign("last", function(data, argset) "the user's last", envir = globalenv())
  on.exit(rm("last", envir = globalenv()), add = TRUE)

  expect_identical(
    get_anything("last", envir = globalenv())(1, 2),
    "the user's last"
  )
})

test_that("fn_name resolves in the environment where the plan is built", {
  e <- new.env(parent = globalenv())
  local(
    {
      data_local <- function() {
        return(10)
      }
      fn_local <- function(data, argset) {
        return(data$d + argset$k)
      }
      p <- Plan$new(verbose = FALSE)
      p$add_data(name = "d", fn_name = "data_local")
      p$add_analysis(name = "one", fn_name = "fn_local", k = 1)
      p$add_analysis_from_list(
        fn_name = "fn_local",
        l = list(list(name = "two", k = 2))
      )
      p$add_analysis_from_df(
        fn_name = "fn_local",
        df = data.frame(name = "three", k = 3)
      )
      p$add_argset(name = "four", k = 4)
    },
    envir = e
  )
  expect_identical(
    lapply(c("one", "two", "three"), e$p$run_one),
    list(11, 12, 13)
  )

  local(p$apply_action_fn_to_all_argsets(fn_name = "fn_local"), envir = e)
  expect_identical(e$p$run_all(), list(11, 12, 13, 14))
})

test_that("a local function wins over a global function with the same name", {
  assign("fn_shared", function(data, argset) "global", envir = globalenv())
  on.exit(rm("fn_shared", envir = globalenv()), add = TRUE)

  build <- function() {
    fn_shared <- function(data, argset) {
      return("local")
    }
    p <- Plan$new(verbose = FALSE)
    p$add_data(name = "d", direct = 1)
    p$add_analysis(name = "a", fn_name = "fn_shared")
    return(p)
  }

  expect_identical(build()$run_one("a"), "local")
})

test_that("a pkg::fn string resolves to that export", {
  expect_identical(get_anything("plnr::test_action_fn"), plnr::test_action_fn)

  p <- Plan$new(verbose = FALSE)
  p$add_data(name = "d", direct = 1)
  p$add_analysis(name = "a", fn_name = "plnr::test_action_fn")
  expect_identical(p$run_one("a"), 1)
})

# pkgload::load_all() attaches every plnr function and every import. Under it
# these two names resolve from the search path, so only the installed package,
# as R CMD check runs it, tests the fallback to the plnr namespace.
test_that("a plnr function that plnr does not export still resolves", {
  expect_identical(
    get_anything("hash_it", envir = globalenv()),
    get("hash_it", envir = asNamespace("plnr"))
  )
})

test_that("an export of a package that plnr imports still resolves", {
  skip_if("package:data.table" %in% search())

  expect_identical(
    get_anything("rbindlist", envir = globalenv()),
    data.table::rbindlist
  )
})

test_that("get_anything() finds the caller's variable, not its own argument", {
  f <- function() {
    x <- 1
    return(get_anything("x"))
  }
  expect_identical(f(), 1)
})
