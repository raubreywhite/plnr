# R CMD check finds an undeclared `pkg::` call in a namespace function, but it
# does not read the methods of an R6 generator. `progress::progress_bar` in a
# Plan method was undeclared for that reason. This test reads both.

test_that("every package that plnr calls with :: is declared in DESCRIPTION", {
  ns <- asNamespace("plnr")
  fns <- c(
    mget(ls(ns, all.names = TRUE), envir = ns),
    Plan$public_methods,
    Plan$private_methods
  )
  fns <- Filter(is.function, fns)
  called <- unique(unlist(lapply(fns, function(f) {
    n <- all.names(body(f))
    return(n[which(n %in% c("::", ":::")) + 1L])
  })))

  desc <- utils::packageDescription("plnr")
  fields <- unlist(strsplit(c(desc$Depends, desc$Imports, desc$Suggests), ","))
  declared <- trimws(sub("\\(.*$", "", fields))
  base <- rownames(utils::installed.packages(priority = "base"))

  undeclared <- setdiff(called, c(declared, base, "plnr"))
  expect_true("progress" %in% called)
  expect_identical(
    undeclared,
    character(),
    info = paste("Undeclared:", toString(undeclared))
  )
})
