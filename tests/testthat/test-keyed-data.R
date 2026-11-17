# A data function with arguments is keyed. Its argument names are argset
# fields. In one run, the plan calls it once for each distinct set of values,
# and every analysis with those values gets the same object.

# A plan with 2 scenarios x 3 sims x 2 outcomes = 12 analyses and 6 keys.
# The data function appends one line to `count_file` for each call, with one
# write call, so processes that write at the same time cannot mix lines.
keyed_plan <- function(count_file, use_foreach = FALSE) {
  offset <- 100
  p <- Plan$new(verbose = FALSE, use_foreach = use_foreach)
  p$add_data("u", direct = "unkeyed")
  p$add_data("d", fn = function(scenario, sim) {
    cat(paste0(scenario, "-", sim, "\n"), file = count_file, append = TRUE)
    return(data.frame(
      scenario = tools::toTitleCase(scenario),
      value = sim + offset
    ))
  })
  p$add_argset_from_list(expand_list(
    scenario = c("null", "real"),
    sim = 1:3,
    outcome = c("a", "b")
  ))
  p$apply_action_fn_to_all_argsets(fn = function(data, argset) {
    return(list(
      names = names(data),
      scenario = argset$scenario,
      sim = argset$sim,
      outcome = argset$outcome,
      d = data$d
    ))
  })
  return(p)
}

expected_value <- function(i) {
  scenario <- rep(c("null", "real"), each = 6)[[i]]
  sim <- rep(rep(1:3, each = 2), times = 2)[[i]]
  return(data.frame(scenario = tools::toTitleCase(scenario), value = sim + 100))
}

expect_keyed_results <- function(r) {
  expect_length(r, 12)
  for (i in seq_len(12)) {
    expect_identical(r[[i]]$names, c("u", "d", "hash"))
    expect_identical(r[[i]]$d, expected_value(i))
  }
  return(invisible(r))
}

test_that("run_all() calls a keyed data function once for each key", {
  count_file <- tempfile()
  r <- keyed_plan(count_file)$run_all()

  calls <- readLines(count_file)
  expect_length(calls, 6)
  expect_setequal(calls, paste0(rep(c("null", "real"), each = 3), "-", 1:3))
  expect_keyed_results(r)
})

test_that("analyses with the same key get the same object", {
  p <- Plan$new(verbose = FALSE)
  p$add_data("d", fn = function(sim) {
    e <- new.env()
    e$sim <- sim
    return(e)
  })
  p$add_argset_from_list(expand_list(sim = 1:2, rep = 1:2))
  p$apply_action_fn_to_all_argsets(fn = function(data, argset) data$d)
  r <- p$run_all()

  expect_true(identical(r[[1]], r[[2]]))
  expect_true(identical(r[[3]], r[[4]]))
  expect_false(identical(r[[1]], r[[3]]))
})

test_that("a different key gives different data", {
  p <- Plan$new(verbose = FALSE)
  p$add_data("d", fn = function(sim) paste("data for sim", sim))
  p$add_argset_from_list(expand_list(sim = 1:3))
  p$apply_action_fn_to_all_argsets(fn = function(data, argset) data$d)

  expect_identical(
    p$run_all(),
    list("data for sim 1", "data for sim 2", "data for sim 3")
  )
})

test_that("an argset without a key field stops the run before any analysis", {
  ran <- 0
  p <- Plan$new(verbose = FALSE)
  p$add_data("d", fn = function(scenario, sim) 1)
  p$add_argset(name = "full", scenario = "a", sim = 1)
  p$add_argset(name = "no_sim", scenario = "a")
  p$apply_action_fn_to_all_argsets(fn = function(data, argset) {
    ran <<- ran + 1
    return(1)
  })

  expect_error(
    p$run_all(),
    "Analysis 'no_sim' has no argset field 'sim', which the data 'd' needs.",
    fixed = TRUE
  )
  expect_identical(ran, 0)
  expect_error(
    p$run_one(2),
    "Analysis 'no_sim' has no argset field 'sim', which the data 'd' needs.",
    fixed = TRUE
  )
})

test_that("a data function with only defaults or ... is called once, as before", {
  calls <- 0
  p <- Plan$new(verbose = FALSE)
  p$add_data("defaulted", fn = function(s = 0) {
    calls <<- calls + 1
    return(s)
  })
  p$add_data("dots", fn = function(...) length(list(...)))
  p$add_data("both", fn = function(a = 1, ...) a)
  p$add_argset(name = "x", s = 5, a = 7)
  p$add_argset(name = "y", s = 6, a = 8)
  p$apply_action_fn_to_all_argsets(fn = function(data, argset) {
    return(data[c("defaulted", "dots", "both")])
  })

  expect_identical(
    p$run_all(),
    rep(list(list(defaulted = 0, dots = 0L, both = 1)), 2)
  )
  expect_identical(calls, 1)
  expect_identical(p$get_data()$defaulted, 0)
})

test_that("only the arguments without a default are key fields", {
  seen <- list()
  p <- Plan$new(verbose = FALSE)
  p$add_data("d", fn = function(sim, scale = 10, ...) {
    seen[[length(seen) + 1]] <<- list(
      sim = sim,
      scale = scale,
      dots = list(...)
    )
    return(sim * scale)
  })
  # `scale` is in the argset, but it is not a key field, so it keeps its default.
  p$add_argset(name = "a", sim = 1, scale = 99)
  p$add_argset(name = "b", sim = 1, scale = 98)
  p$add_argset(name = "c", sim = 2)
  p$apply_action_fn_to_all_argsets(fn = function(data, argset) data$d)

  expect_identical(p$run_all(), list(10, 10, 20))
  expect_identical(
    seen,
    list(
      list(sim = 1, scale = 10, dots = list()),
      list(sim = 2, scale = 10, dots = list())
    )
  )
})

test_that("run_all() drops a keyed dataset when no remaining analysis needs it", {
  # A finalizer records each dataset that the garbage collector frees. Each
  # analysis returns what was freed before it ran.
  freed <- integer()
  p <- Plan$new(verbose = FALSE)
  p$add_data("d", fn = function(sim) {
    e <- new.env()
    e$sim <- sim
    reg.finalizer(e, function(x) freed <<- c(freed, x$sim))
    return(e)
  })
  p$add_argset_from_list(expand_list(sim = 1:3, rep = 1:2))
  p$apply_action_fn_to_all_argsets(fn = function(data, argset) {
    gc()
    return(sort(freed))
  })
  r <- p$run_all()

  expect_identical(
    r,
    list(integer(), integer(), 1L, 1L, 1:2, 1:2)
  )
})

test_that("get_data() takes an analysis for keyed data", {
  calls <- 0
  p <- Plan$new(verbose = FALSE)
  p$add_data("u", direct = "unkeyed")
  p$add_data("d", fn = function(sim) {
    calls <<- calls + 1
    return(sim * 10)
  })
  p$add_argset(name = "first", sim = 1)
  p$add_argset(name = "second", sim = 2)

  expect_identical(p$get_data(2)$d, 20)
  expect_identical(p$get_data("first")$d, 10)
  expect_identical(names(p$get_data(1)), c("u", "d", "hash"))
  expect_identical(calls, 3)
  expect_error(
    p$get_data(),
    "The data 'd' depends on the argset. Give get_data() an analysis",
    fixed = TRUE
  )
  expect_error(
    p$get_data("third"),
    "The plan has no analysis third.",
    fixed = TRUE
  )
  expect_error(p$get_data(3), "The plan has no analysis 3.", fixed = TRUE)
})

test_that("get_data() without keyed data does not use the analysis", {
  p <- Plan$new(verbose = FALSE)
  p$add_data("d", fn = function() 1)
  p$add_argset(name = "a", sim = 1)

  expect_identical(p$get_data("no such analysis"), p$get_data())
})

test_that("run_one() calls a keyed data function for its own analysis", {
  count_file <- tempfile()
  p <- keyed_plan(count_file)

  expect_identical(p$run_one(8)$d, expected_value(8))
  expect_identical(readLines(count_file), "real-1")
})

test_that("the run methods with data call no keyed data function", {
  count_file <- tempfile()
  p <- keyed_plan(count_file)
  given <- list(u = "given", d = "given")

  expect_identical(p$run_one_with_data(1, given)$d, "given")
  r <- p$run_all_with_data(given)
  expect_identical(unique(lapply(r, function(x) x$d)), list("given"))
  expect_false(file.exists(count_file))
})

test_that("keyed and unkeyed data keep the order of add_data()", {
  unkeyed_calls <- 0
  p <- Plan$new(verbose = FALSE)
  p$add_data("first", direct = 1)
  p$add_data("keyed", fn = function(sim) sim)
  p$add_data("last", fn = function() {
    unkeyed_calls <<- unkeyed_calls + 1
    return("once")
  })
  p$add_argset_from_list(expand_list(sim = 1:3))
  p$apply_action_fn_to_all_argsets(fn = function(data, argset) data)
  r <- p$run_all()

  expect_identical(unkeyed_calls, 1)
  for (i in 1:3) {
    expect_identical(names(r[[i]]), c("first", "keyed", "last", "hash"))
    expect_identical(
      r[[i]][c("first", "keyed", "last")],
      list(first = 1, keyed = i, last = "once")
    )
  }
})

test_that("a keyed value is exact: 1 and 1L are different keys", {
  seen <- character()
  p <- Plan$new(verbose = FALSE)
  p$add_data("d", fn = function(k) {
    seen <<- c(seen, typeof(k))
    return(typeof(k))
  })
  p$add_argset(name = "double", k = 1)
  p$add_argset(name = "integer", k = 1L)
  p$add_argset(name = "double_again", k = 1)
  p$apply_action_fn_to_all_argsets(fn = function(data, argset) data$d)

  expect_identical(p$run_all(), list("double", "integer", "double"))
  expect_identical(seen, c("double", "integer"))
})

test_that("a keyed value is exact: NA, NULL and vectors", {
  seen <- list()
  p <- Plan$new(verbose = FALSE)
  p$add_data("d", fn = function(k) {
    seen <<- c(seen, list(k))
    return(length(seen))
  })
  p$add_argset(name = "na_1", k = NA)
  p$add_argset(name = "na_2", k = NA)
  p$add_argset(name = "na_chr", k = NA_character_)
  p$add_argset(name = "null_1", k = NULL)
  p$add_argset(name = "null_2", k = NULL)
  p$add_argset(name = "vec_1", k = c(1, 2))
  p$add_argset(name = "vec_2", k = c(1, 2))
  p$add_argset(name = "vec_rev", k = c(2, 1))
  p$apply_action_fn_to_all_argsets(fn = function(data, argset) data$d)

  expect_identical(p$run_all(), list(1L, 1L, 2L, 3L, 3L, 4L, 4L, 5L))
  expect_identical(seen, list(NA, NA_character_, NULL, c(1, 2), c(2, 1)))
})

test_that("keyed data can be the single data__________go_up_one_level", {
  p <- Plan$new(verbose = FALSE)
  p$add_data("data__________go_up_one_level", fn = function(sim) {
    return(list(a = sim, b = -sim))
  })
  p$add_argset_from_list(expand_list(sim = 1:2))
  p$apply_action_fn_to_all_argsets(fn = function(data, argset) data)
  r <- p$run_all()

  expect_identical(names(r[[2]]), c("a", "b", "hash"))
  expect_identical(r[[2]][c("a", "b")], list(a = 2L, b = -2L))
})

test_that("two keyed sources with different fields: each key once on run_all()", {
  count_file <- tempfile()
  p <- Plan$new(verbose = FALSE)
  p$add_data("by_scenario", fn = function(scenario) {
    cat("scenario\n", file = count_file, append = TRUE)
    return(scenario)
  })
  p$add_data("by_sim", fn = function(sim) {
    cat("sim\n", file = count_file, append = TRUE)
    return(sim)
  })
  p$add_argset_from_list(expand_list(scenario = c("x", "y"), sim = 1:3))
  p$apply_action_fn_to_all_argsets(fn = function(data, argset) {
    return(paste(data$by_scenario, data$by_sim))
  })
  sequential <- p$run_all()
  expect_identical(as.vector(table(readLines(count_file))), c(2L, 3L))

  # The two fields cross, so every analysis is in one group.
  keys <- lapply(1:6, function(i) {
    return(p$.__enclos_env__$private$keyed_keys(
      p$.__enclos_env__$private$resolve_data(),
      i
    ))
  })
  expect_identical(keyed_groups(keys), list(1:6))

  unlink(count_file)
  foreach::registerDoSEQ()
  p$set_use_foreach(TRUE)
  expect_identical(p$run_all(), sequential)
  expect_identical(as.vector(table(readLines(count_file))), c(2L, 3L))
})

test_that("groups are the connected analyses: nested fields give one per scenario", {
  keys <- list(
    c(s = "x", ss = "x1"),
    c(s = "x", ss = "x2"),
    c(s = "y", ss = "y1"),
    c(s = "y", ss = "y1"),
    c(s = "z", ss = "z1")
  )
  expect_identical(keyed_groups(keys), list(1:2, 3:4, 5L))
  # Analysis 3 links the groups of 1 and of 2 through two sources.
  keys <- list(c(a = "1", b = "p"), c(a = "2", b = "q"), c(a = "1", b = "q"))
  expect_identical(keyed_groups(keys), list(1:3))
})

# ---- the parallel paths ----

# Two keyed sources on different fields: one by scenario, one by scenario and
# sim. With `random = TRUE` each call returns a new random number, so two
# calls for the same key would give different data.
two_source_plan <- function(count_file, random, use_foreach = FALSE) {
  p <- Plan$new(verbose = FALSE, use_foreach = use_foreach)
  p$add_data("by_scenario", fn = function(scenario) {
    cat(
      paste0("by_scenario ", scenario, "\n"),
      file = count_file,
      append = TRUE
    )
    if (random) {
      return(sample.int(1e9, 1))
    }
    return(nchar(scenario))
  })
  p$add_data("by_cell", fn = function(scenario, sim) {
    cat(
      paste0("by_cell ", scenario, " ", sim, "\n"),
      file = count_file,
      append = TRUE
    )
    if (random) {
      return(sample.int(1e9, 1))
    }
    return(paste(scenario, sim))
  })
  p$add_argset_from_list(expand_list(
    scenario = c("null", "real"),
    sim = 1:3,
    outcome = c("a", "b")
  ))
  p$apply_action_fn_to_all_argsets(fn = function(data, argset) {
    return(list(
      scenario = argset$scenario,
      sim = argset$sim,
      s = data$by_scenario,
      c = data$by_cell
    ))
  })
  return(p)
}

# Analyses that share a key got the same data, and each key ran once.
expect_shared_keys <- function(r, count_file) {
  scenario <- vapply(r, function(x) x$scenario, character(1))
  cell <- vapply(r, function(x) paste(x$scenario, x$sim), character(1))
  s <- vapply(r, function(x) as.character(x$s), character(1))
  c <- vapply(r, function(x) as.character(x$c), character(1))
  for (k in unique(scenario)) {
    expect_length(unique(s[scenario == k]), 1)
  }
  for (k in unique(cell)) {
    expect_length(unique(c[cell == k]), 1)
  }
  calls <- readLines(count_file)
  expect_identical(
    as.vector(table(sub(" .*$", "", calls))[c("by_scenario", "by_cell")]),
    c(2L, 6L)
  )
  expect_length(unique(calls), 8)
  return(invisible(NULL))
}


test_that("run_all() with foreach on doSEQ calls the function once for each key", {
  foreach::registerDoSEQ()
  sequential <- keyed_plan(tempfile())$run_all()
  count_file <- tempfile()
  r <- keyed_plan(count_file, use_foreach = TRUE)$run_all()

  expect_length(readLines(count_file), 6)
  expect_identical(r, sequential)
  expect_keyed_results(r)
})

test_that("run_all() with forked doParallel workers calls once for each key", {
  skip_on_os("windows")
  skip_if_not_installed("doParallel")
  sequential <- keyed_plan(tempfile())$run_all()
  doParallel::registerDoParallel(cores = 2)
  on.exit(doParallel::stopImplicitCluster(), add = TRUE)
  on.exit(foreach::registerDoSEQ(), add = TRUE)
  count_file <- tempfile()
  r <- keyed_plan(count_file, use_foreach = TRUE)$run_all()

  calls <- readLines(count_file)
  expect_length(calls, 6)
  expect_length(unique(calls), 6)
  expect_identical(r, sequential)
})

test_that("run_all_parallel() calls the function once for each key", {
  skip_on_os("windows")
  sequential <- keyed_plan(tempfile())$run_all()
  count_file <- tempfile()
  p <- keyed_plan(count_file)
  utils::capture.output(r <- p$run_all_parallel(mc.cores = 2))

  calls <- readLines(count_file)
  expect_length(calls, 6)
  expect_length(unique(calls), 6)
  expect_identical(r, sequential)
})

test_that("run_all_parallel() puts each result and each error at its analysis", {
  skip_on_os("windows")
  count_file <- tempfile()
  p <- Plan$new(verbose = FALSE)
  p$add_data("d", fn = function(sim) {
    cat(paste0(sim, "\n"), file = count_file, append = TRUE)
    if (sim == 3) {
      stop("data failed")
    }
    return(sim)
  })
  p$add_argset_from_list(expand_list(sim = 1:3, rep = 1:2))
  p$apply_action_fn_to_all_argsets(fn = function(data, argset) {
    if (argset$sim == 2 && argset$rep == 1) {
      stop("action failed")
    }
    return(data$d)
  })
  utils::capture.output(r <- p$run_all_parallel(mc.cores = 2))

  expect_identical(r[c(1, 2, 4)], list(1L, 1L, 2L))
  for (i in c(3, 5, 6)) {
    expect_s3_class(r[[i]], "try-error")
  }
  expect_identical(conditionMessage(attr(r[[3]], "condition")), "action failed")
  expect_identical(conditionMessage(attr(r[[5]], "condition")), "data failed")
  expect_identical(conditionMessage(attr(r[[6]], "condition")), "data failed")
  # The failed data function ran once for its key.
  expect_identical(sort(readLines(count_file)), c("1", "2", "3"))
})

test_that("every keyed path keeps a NULL result at its own position", {
  p <- Plan$new(verbose = FALSE)
  p$add_data("d", fn = function(sim) sim)
  p$add_argset_from_list(expand_list(sim = 1:2, rep = 1:3))
  p$apply_action_fn_to_all_argsets(fn = function(data, argset) {
    if (argset$rep == 3) {
      return(NULL)
    }
    return(data$d)
  })
  # NULL in the middle and at the end, so that a dropped NULL shows.
  expected <- list(1L, 1L, NULL, 2L, 2L, NULL)

  expect_identical(p$run_all(), expected)
  foreach::registerDoSEQ()
  p$set_use_foreach(TRUE)
  expect_identical(p$run_all(), expected)
  p$set_use_foreach(FALSE)
  skip_on_os("windows")
  utils::capture.output(r <- p$run_all_parallel(mc.cores = 2))
  expect_identical(r, expected)
})

test_that("run_all_progress() calls the function once for each key", {
  skip_if_not_installed("progressr")
  sequential <- keyed_plan(tempfile())$run_all()
  count_file <- tempfile()
  r <- keyed_plan(count_file)$run_all_progress()

  expect_length(readLines(count_file), 6)
  expect_identical(r, sequential)
})

test_that("run_all() on a PSOCK cluster calls the function once for each key", {
  skip_on_cran()
  skip_if_not_installed("doParallel")
  skip_if_not(
    file.exists(system.file("Meta", "package.rds", package = "plnr")),
    "PSOCK workers load plnr from a library, so plnr must be installed"
  )
  sequential <- keyed_plan(tempfile())$run_all()

  cl <- parallel::makePSOCKcluster(2)
  on.exit(parallel::stopCluster(cl), add = TRUE)
  on.exit(foreach::registerDoSEQ(), add = TRUE)
  set_lib <- function(paths) .libPaths(paths)
  environment(set_lib) <- baseenv()
  parallel::clusterCall(cl, set_lib, .libPaths())
  doParallel::registerDoParallel(cl)
  worker_pids <- unlist(parallel::clusterCall(cl, Sys.getpid))

  # keyed_plan() defines its data function in this file. The function uses a
  # variable of its enclosing frame and a function of the tools package.
  count_file <- tempfile()
  p <- keyed_plan(count_file, use_foreach = TRUE)
  r <- p$run_all()

  calls <- readLines(count_file)
  expect_length(calls, 6)
  expect_length(unique(calls), 6)
  expect_identical(r, sequential)

  # The data function runs on a worker.
  p$add_data("pid", fn = function(sim) Sys.getpid())
  p$apply_action_fn_to_all_argsets(fn = function(data, argset) data$pid)
  pids <- unlist(p$run_all())
  expect_true(all(pids %in% worker_pids))
})

test_that("two sources, random data: run_all() in sequence shares each key", {
  count_file <- tempfile()
  expect_shared_keys(two_source_plan(count_file, TRUE)$run_all(), count_file)
})

test_that("two sources, random data: foreach on doSEQ shares each key", {
  foreach::registerDoSEQ()
  count_file <- tempfile()
  r <- two_source_plan(count_file, TRUE, use_foreach = TRUE)$run_all()
  expect_shared_keys(r, count_file)

  sequential <- two_source_plan(tempfile(), FALSE)$run_all()
  r <- two_source_plan(tempfile(), FALSE, use_foreach = TRUE)$run_all()
  expect_identical(r, sequential)
})

test_that("two sources, random data: forked doParallel workers share each key", {
  skip_on_os("windows")
  skip_if_not_installed("doParallel")
  doParallel::registerDoParallel(cores = 2)
  on.exit(doParallel::stopImplicitCluster(), add = TRUE)
  on.exit(foreach::registerDoSEQ(), add = TRUE)
  count_file <- tempfile()
  r <- two_source_plan(count_file, TRUE, use_foreach = TRUE)$run_all()
  expect_shared_keys(r, count_file)

  sequential <- two_source_plan(tempfile(), FALSE)$run_all()
  r <- two_source_plan(tempfile(), FALSE, use_foreach = TRUE)$run_all()
  expect_identical(r, sequential)
})

test_that("two sources, random data: run_all_parallel() shares each key", {
  skip_on_os("windows")
  count_file <- tempfile()
  utils::capture.output(
    r <- two_source_plan(count_file, TRUE)$run_all_parallel(mc.cores = 2)
  )
  expect_shared_keys(r, count_file)

  sequential <- two_source_plan(tempfile(), FALSE)$run_all()
  utils::capture.output(
    r <- two_source_plan(tempfile(), FALSE)$run_all_parallel(mc.cores = 2)
  )
  expect_identical(r, sequential)
})

test_that("PSOCK: two sources share each key; data functions and their objects", {
  skip_on_cran()
  skip_if_not_installed("doParallel")
  skip_if_not(
    file.exists(system.file("Meta", "package.rds", package = "plnr")),
    "PSOCK workers load plnr from a library, so plnr must be installed"
  )
  cl <- parallel::makePSOCKcluster(2)
  on.exit(parallel::stopCluster(cl), add = TRUE)
  on.exit(foreach::registerDoSEQ(), add = TRUE)
  set_lib <- function(paths) .libPaths(paths)
  environment(set_lib) <- baseenv()
  parallel::clusterCall(cl, set_lib, .libPaths())
  doParallel::registerDoParallel(cl)

  count_file <- tempfile()
  r <- two_source_plan(count_file, TRUE, use_foreach = TRUE)$run_all()
  expect_shared_keys(r, count_file)
  sequential <- two_source_plan(tempfile(), FALSE)$run_all()
  r <- two_source_plan(tempfile(), FALSE, use_foreach = TRUE)$run_all()
  expect_identical(r, sequential)

  # (a) An object of the enclosing environment reaches the worker.
  enclosing_object <- 1000
  p <- Plan$new(verbose = FALSE, use_foreach = TRUE)
  p$add_data("d", fn = function(sim) sim + enclosing_object)
  p$add_argset_from_list(expand_list(sim = 1:2))
  p$apply_action_fn_to_all_argsets(fn = function(data, argset) data$d)
  expect_identical(p$run_all(), list(1001, 1002))

  # (b) An object of the global environment does not reach the worker.
  assign("plnr_test_global_object", 2000, envir = globalenv())
  on.exit(rm("plnr_test_global_object", envir = globalenv()), add = TRUE)
  global_fn <- function(sim) sim + plnr_test_global_object
  environment(global_fn) <- globalenv()
  p <- Plan$new(verbose = FALSE, use_foreach = TRUE)
  p$add_data("d", fn = global_fn)
  p$add_argset_from_list(expand_list(sim = 1:2))
  p$apply_action_fn_to_all_argsets(fn = function(data, argset) data$d)
  expect_error(p$run_all(), "object 'plnr_test_global_object' not found")
  # The same plan runs in sequence, where the global environment is shared.
  p$set_use_foreach(FALSE)
  expect_identical(p$run_all(), list(2001, 2002))
})
