# A plan stores an environment with fn_name only when the name resolves in a
# local environment at the time you add it, and then only that environment.
# It stored the whole calling frame, which kept every object in it alive.

test_that("a name that resolves outside local frames stores no environment", {
  p <- local({
    unrelated <- raw(10 * 1024^2)
    p <- Plan$new(verbose = FALSE)
    p$add_analysis("a", fn_name = "test_action_fn")
    source <- p$add_data(
      "d",
      fn_name = "example_data_fn_nor_covid19_cases_by_time_location"
    )
    attr(p, "source_fn_env") <- source[["fn_env"]]
    p
  })

  expect_null(p$analyses$a$fn_env)
  expect_null(attr(p, "source_fn_env"))
  expect_lt(length(serialize(p$analyses, NULL)), 1024^2)
  expect_identical(p$run_one("a"), 1)
})

test_that("a plan stores the environment where the name resolves", {
  make <- function() {
    helper_fn <- function(data, argset) {
      return("from the enclosing frame")
    }
    build <- function() {
      unrelated <- raw(10 * 1024^2)
      p <- Plan$new(verbose = FALSE)
      p$add_data("d", direct = 1)
      p$add_analysis("a", fn_name = "helper_fn")
      return(p)
    }
    return(build())
  }
  p <- make()

  env <- p$analyses$a$fn_env
  expect_true(exists("helper_fn", envir = env, inherits = FALSE))
  expect_false(exists("unrelated", envir = env, inherits = FALSE))
  expect_identical(p$run_one("a"), "from the enclosing frame")
})
