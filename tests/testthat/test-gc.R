# plnr called gc() after every analysis. One full collection took about 45 ms
# with data.table and ggplot2 loaded, so a plan of many small analyses spent
# most of its run time there. plnr now never calls gc(). R collects by itself.

# Run `p$run_all()` and return how often base::gc() ran.
count_gc <- function(p) {
  counter <- new.env()
  counter$n <- 0L
  suppressMessages(trace(
    "gc",
    tracer = substitute(
      assign("n", get("n", envir = counter) + 1L, envir = counter),
      list(counter = counter)
    ),
    where = baseenv(),
    print = FALSE
  ))
  on.exit(suppressMessages(untrace("gc", where = baseenv())), add = TRUE)
  p$run_all()
  return(counter$n)
}

unkeyed_plan <- function(n, use_foreach = FALSE) {
  p <- Plan$new(verbose = FALSE, use_foreach = use_foreach)
  p$add_data("d", direct = 1)
  p$add_argset_from_list(lapply(seq_len(n), function(i) return(list(i = i))))
  p$apply_action_fn_to_all_argsets(fn = function(data, argset) {
    return(argset$i)
  })
  return(p)
}

keyed_plan_n <- function(n, n_keys) {
  p <- Plan$new(verbose = FALSE)
  p$add_data("d", fn = function(k) return(k))
  p$add_argset_from_list(lapply(seq_len(n), function(i) {
    return(list(i = i, k = i %% n_keys))
  }))
  p$apply_action_fn_to_all_argsets(fn = function(data, argset) {
    return(data$d)
  })
  return(p)
}

test_that("run_all() does not call gc() for unkeyed analyses", {
  expect_identical(count_gc(unkeyed_plan(5)), 0L)
  expect_identical(count_gc(unkeyed_plan(50)), 0L)
})

test_that("run_all() with foreach does not call gc() for unkeyed analyses", {
  foreach::registerDoSEQ()
  expect_identical(count_gc(unkeyed_plan(5, use_foreach = TRUE)), 0L)
  expect_identical(count_gc(unkeyed_plan(50, use_foreach = TRUE)), 0L)
})

test_that("run_all() does not call gc() for keyed analyses", {
  expect_identical(count_gc(keyed_plan_n(6, 3)), 0L)
  expect_identical(count_gc(keyed_plan_n(60, 3)), 0L)
})
