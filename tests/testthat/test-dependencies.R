# R CMD check finds an undeclared `pkg::` call in a namespace function, but it
# does not read the methods of an R6 generator. `progress::progress_bar` in a
# Plan method was undeclared for that reason. These tests read both.
#
# A package in Suggests MAY be missing, so plnr MUST check for it before it
# calls it. Here a call counts as guarded when the same function also calls
# requireNamespace() with that package name. Every other `pkg::` call MUST name
# a package in Imports.

plnr_functions <- function() {
  ns <- asNamespace("plnr")
  fns <- c(
    mget(ls(ns, all.names = TRUE), envir = ns),
    Plan$public_methods,
    Plan$private_methods
  )
  return(Filter(is.function, fns))
}

called_in <- function(f) {
  n <- all.names(body(f))
  return(unique(n[which(n %in% c("::", ":::")) + 1L]))
}

guarded_in <- function(f) {
  src <- paste(deparse(body(f)), collapse = "\n")
  found <- regmatches(src, gregexpr('requireNamespace\\("[^"]+"', src))[[1]]
  return(unique(sub('^requireNamespace\\("', "", sub('"$', "", found))))
}

declared_in <- function(field) {
  x <- utils::packageDescription("plnr")[[field]]
  if (is.null(x)) {
    return(character())
  }
  return(trimws(sub("\\(.*$", "", unlist(strsplit(x, ",")))))
}

test_that("every package that plnr calls unguarded with :: is in Imports", {
  unguarded <- unique(unlist(lapply(plnr_functions(), function(f) {
    return(setdiff(called_in(f), guarded_in(f)))
  })))
  missing <- setdiff(unguarded, c(declared_in("Imports"), "base", "plnr"))

  expect_true("progress" %in% unguarded)
  expect_identical(
    missing,
    character(),
    info = paste("Called unguarded, but not in Imports:", toString(missing))
  )
})

test_that("every package that plnr calls with :: is declared", {
  called <- unique(unlist(lapply(plnr_functions(), called_in)))
  missing <- setdiff(
    called,
    c(declared_in("Imports"), declared_in("Suggests"), "base", "plnr")
  )

  expect_true("progressr" %in% called)
  expect_identical(
    missing,
    character(),
    info = paste("Not in DESCRIPTION:", toString(missing))
  )
})
