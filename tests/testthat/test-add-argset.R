# add_argset() and add_analysis() wrote `analyses[[name]] <- list()`. In a
# method of this non-portable R6 class, `<-` creates a local copy of the whole
# analyses list, and the method then discards that copy. The stored plan ends
# up the same either way, so the defect shows only as the copy, which
# tracemem() reports.

count_copies <- function(p, code) {
  tracemem(p$analyses)
  on.exit(untracemem(p$analyses))
  out <- utils::capture.output(code)
  return(sum(grepl("^tracemem\\[", out)))
}

test_that("add_argset() changes the analyses list without a copy", {
  skip_on_cran()
  skip_if_not(capabilities("profmem"))

  p <- Plan$new(verbose = FALSE)
  p$add_argset("a", k = 1)

  expect_identical(count_copies(p, p$add_argset("b", k = 2)), 0L)
  expect_identical(p$analyses[["b"]], list(argset = list(k = 2)))
})

test_that("add_analysis() changes the analyses list without a copy", {
  skip_on_cran()
  skip_if_not(capabilities("profmem"))

  p <- Plan$new(verbose = FALSE)
  p$add_analysis("a", fn_name = "plnr::test_action_fn", k = 1)

  expect_identical(
    count_copies(p, p$add_analysis("b", fn_name = "plnr::test_action_fn")),
    0L
  )
  expect_identical(p$analyses[["b"]][["argset"]], list())
})

test_that("add_argset() stores an empty argset as an empty list", {
  p <- Plan$new(verbose = FALSE)
  p$add_argset("a")

  expect_identical(p$analyses[["a"]], list(argset = list()))
})
