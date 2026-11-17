# plnr calls gc(FALSE) after an analysis only when gc_interval_seconds of
# elapsed time passed since its last collection in this process. One call
# took about 46 ms with data.table and ggplot2 loaded. A collection after
# every analysis made a plan of 2,000 small analyses take 92 s.

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

# Replace the clock with one that returns `times` in order, one value for
# each call. Replace the state with one whose last collection is at `last`.
# The state of the package stays as it was.
local_scripted_clock <- function(times, last = 0, env = parent.frame()) {
  clock <- new.env()
  clock$i <- 0L
  state <- new.env(parent = emptyenv())
  state$last <- last
  local_mocked_bindings(
    gc_clock = function() {
      clock$i <- clock$i + 1L
      return(times[[clock$i]])
    },
    gc_state = state,
    .env = env
  )
  return(invisible(list(clock = clock, state = state)))
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

keyed_plan_n <- function(n, n_keys, use_foreach = FALSE) {
  p <- Plan$new(verbose = FALSE, use_foreach = use_foreach)
  p$add_data("d", fn = function(k) return(k))
  p$add_argset_from_list(lapply(seq_len(n), function(i) {
    return(list(i = i, k = i %% n_keys))
  }))
  p$apply_action_fn_to_all_argsets(fn = function(data, argset) {
    return(data$d)
  })
  return(p)
}

# Ten checks, one after each of ten analyses. With the last collection at 0,
# plnr collects at 1.0, 2.5, 3.6 and 10, so four times.
scripted_times <- c(0.2, 0.9, 1.0, 1.1, 2.5, 2.6, 3.4, 3.6, 10, 10.5)

test_that("a fast unkeyed plan collects at most once", {
  expect_lte(count_gc(unkeyed_plan(50)), 1L)
  foreach::registerDoSEQ()
  expect_lte(count_gc(unkeyed_plan(50, use_foreach = TRUE)), 1L)
})

test_that("a fast keyed plan collects at most once", {
  expect_lte(count_gc(keyed_plan_n(60, 3)), 1L)
  foreach::registerDoSEQ()
  expect_lte(count_gc(keyed_plan_n(60, 3, use_foreach = TRUE)), 1L)
})

test_that("the first check in a process only records the time", {
  s <- local_scripted_clock(c(5, 5.5, 6), last = NULL)
  expect_identical(count_gc(unkeyed_plan(3)), 1L)
  expect_identical(s$state$last, 6)
})

test_that("a slow sequential plan collects once for each interval", {
  s <- local_scripted_clock(scripted_times)
  expect_identical(count_gc(unkeyed_plan(10)), 4L)
  expect_identical(s$clock$i, 10L)
  expect_identical(s$state$last, 10)
})

test_that("a slow foreach plan collects once for each interval", {
  foreach::registerDoSEQ()
  local_scripted_clock(scripted_times)
  expect_identical(count_gc(unkeyed_plan(10, use_foreach = TRUE)), 4L)
  local_scripted_clock(scripted_times)
  expect_identical(
    unkeyed_plan(10, use_foreach = TRUE)$run_all(),
    as.list(seq_len(10))
  )
})

test_that("a slow keyed plan collects once for each interval", {
  local_scripted_clock(scripted_times)
  expect_identical(count_gc(keyed_plan_n(10, 3)), 4L)
  foreach::registerDoSEQ()
  local_scripted_clock(scripted_times)
  expect_identical(count_gc(keyed_plan_n(10, 3, use_foreach = TRUE)), 4L)
})
