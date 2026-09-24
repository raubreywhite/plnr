# On a PSOCK cluster each analysis runs in another R process. The plan
# travels there serialised, together with the environment that it stores for
# a local fn_name. The foreach tests elsewhere use doSEQ, which shares memory,
# so they cannot see what a worker is missing.

test_that("run_all() returns the right values from a 2-worker PSOCK cluster", {
  skip_on_cran()
  skip_if_not_installed("doParallel")
  skip_if_not(
    file.exists(system.file("Meta", "package.rds", package = "plnr")),
    "PSOCK workers load plnr from a library, so plnr must be installed"
  )

  cl <- parallel::makePSOCKcluster(2)
  on.exit(parallel::stopCluster(cl), add = TRUE)
  on.exit(foreach::registerDoSEQ(), add = TRUE)
  # A serialised .libPaths() carries a copy of its own state and changes
  # nothing on the worker. This wrapper calls the worker's own .libPaths().
  set_lib <- function(paths) .libPaths(paths)
  environment(set_lib) <- baseenv()
  parallel::clusterCall(cl, set_lib, .libPaths())
  doParallel::registerDoParallel(cl)
  worker_pids <- unlist(parallel::clusterCall(cl, Sys.getpid))

  make_plan <- function() {
    local_action <- function(data, argset) {
      return(list(value = paste(argset$label, data$d), pid = Sys.getpid()))
    }
    p <- Plan$new(verbose = FALSE, use_foreach = TRUE)
    p$add_data("d", direct = "data")
    p$add_analysis("local", fn_name = "local_action", label = "local")
    p$add_analysis("qualified", fn_name = "plnr::test_action_fn")
    return(p)
  }
  results <- make_plan()$run_all()

  expect_identical(results[[1]]$value, "local data")
  expect_true(results[[1]]$pid %in% worker_pids)
  expect_false(results[[1]]$pid == Sys.getpid())
  expect_identical(results[[2]], 1)
})
