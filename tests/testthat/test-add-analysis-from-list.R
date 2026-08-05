# `add_analysis_from_list()` decides whether to apply the method-level `fn_name`
# by looking at the argset it is about to submit. It once looked at `names(df)`,
# where `df` is neither a parameter of the method nor defined in it. That never
# failed in ordinary use, because `Plan` is a non-portable R6 class whose method
# environment chains through the plnr namespace to the global environment and on
# to the search path, where `stats::df` (the F density) answered the lookup.
# `names(stats::df)` is NULL, so the guard always passed and the mistake stayed
# invisible until R CMD check loaded a dependent package without attaching stats.
#
# A test that merely calls the method passes either way, because `names(NULL)`
# and `names(stats::df)` are both NULL and lead to the same branch. Every block
# below therefore exercises the case the two versions treat DIFFERENTLY: an
# argset that already carries its own `fn_name`. `names(argset)` contains
# "fn_name", so the correct guard skips and the argset keeps its value;
# `names(stats::df)` is NULL, so the defective guard proceeds and overwrites it.
#
# That is behaviour rather than implementation, it is the precedence rule
# `add_analysis_from_df()` already applies, and it discriminates the defect
# without touching the search path or any shared state.

test_that("an argset that carries its own fn_name keeps it", {
  p <- plnr::Plan$new()
  p$add_analysis_from_list(
    fn_name = "plnr::example_action_fn",
    l = list(
      list(name = "own", fn_name = "plnr::test_action_fn", var_1 = 1),
      list(name = "inherit", var_1 = 2)
    )
  )

  expect_equal(p$analyses[["own"]][["fn_name"]], "plnr::test_action_fn")
  expect_equal(p$analyses[["inherit"]][["fn_name"]], "plnr::example_action_fn")
})

test_that("the list and data frame variants agree on fn_name precedence", {
  from_list <- plnr::Plan$new()
  from_list$add_analysis_from_list(
    fn_name = "plnr::example_action_fn",
    l = list(
      list(name = "a", fn_name = "plnr::test_action_fn", var_1 = 1),
      list(name = "b", fn_name = "plnr::test_action_fn", var_1 = 2)
    )
  )

  from_df <- plnr::Plan$new()
  from_df$add_analysis_from_df(
    fn_name = "plnr::example_action_fn",
    df = data.frame(
      name = c("a", "b"),
      fn_name = c("plnr::test_action_fn", "plnr::test_action_fn"),
      var_1 = 1:2,
      stringsAsFactors = FALSE
    )
  )

  expect_equal(
    lapply(from_list$analyses, function(x) x[["fn_name"]]),
    lapply(from_df$analyses, function(x) x[["fn_name"]])
  )
})

test_that("an analysis added from a list with its own fn_name runs that function", {
  p <- plnr::Plan$new()
  p$add_data(
    name = "deaths",
    direct = data.table::data.table(deaths = 1:4, year = 2001:2004)
  )
  p$add_analysis_from_list(
    fn_name = "plnr::example_action_fn",
    l = list(list(
      name = "constant",
      fn_name = "plnr::test_action_fn",
      var_1 = 1
    ))
  )

  # test_action_fn() returns 1; example_action_fn() prints and returns NULL.
  expect_equal(p$run_one("constant"), 1)
})
