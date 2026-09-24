#' Example action function that shows the analysis structure
#'
#' `example_action_fn()` shows how to structure an action function for the
#' `Plan` class. It prints the names of the data and argset components it
#' receives.
#'
#' @param data A named list that holds the datasets for the analysis.
#' @param argset A named list that holds the arguments for the analysis.
#' @return NULL. `example_action_fn()` prints information about the input data
#' and argset.
#' @examples
#' # Create a new plan
#' p <- plnr::Plan$new()
#'
#' # Add example data
#' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
#'
#' # Create batch of argsets
#' batch_argset_list <- list(
#'   list(name = "analysis_1", var_1 = 1, var_2 = "i"),
#'   list(name = "analysis_2", var_1 = 2, var_2 = "j"),
#'   list(name = "analysis_3", var_1 = 3, var_2 = "k")
#' )
#'
#' # Add analyses to plan
#' p$add_analysis_from_list(
#'   fn_name = "plnr::example_action_fn",
#'   l = batch_argset_list
#' )
#'
#' # View argsets and run example
#' p$get_argsets_as_dt()
#' p$run_one("analysis_1")
#' @family example and test functions
#' @seealso `vignette("adding_analyses")` for worked single-function and
#' multi-function plans. Those plans attach an action function to a plan by
#' `fn_name`.
#' @export
example_action_fn <- function(data, argset) {
  print("Data given:")
  print(names(data))
  print("Argset given:")
  print(names(argset))
  return(invisible(names(argset)))
}

#' Test action function that returns a constant value
#'
#' `test_action_fn()` always returns 1. Use it to test the `Plan` framework.
#'
#' @param data A named list that holds the datasets. This example does not use
#' it.
#' @param argset A named list that holds the arguments. This example does not
#' use it.
#' @return The integer 1
#' @examples
#' # Called directly, it ignores both arguments and returns 1
#' test_action_fn(data = list(), argset = list())
#'
#' # Its intended use is as a placeholder action function inside a plan
#' p <- plnr::Plan$new()
#' p$add_data(
#'   name = "deaths",
#'   direct = data.table::data.table(deaths = 1:4, year = 2001:2004)
#' )
#' p$add_analysis(name = "analysis_1", fn_name = "plnr::test_action_fn")
#' p$run_one("analysis_1")
#' @family example and test functions
#' @seealso `vignette("plnr")` for the `data`/`argset` contract. An action
#' function MUST accept at least the supplied data and argset values. It MAY
#' take further arguments. A directly supplied `fn` receives the argset
#' positionally, so its second formal need not be named `argset`.
#' @export
test_action_fn <- function(data, argset) {
  return(1)
}

#' Generate a UUID
#'
#' `uuid_generator()` is an internal function. It generates a unique identifier
#' with the uuid package.
#'
#' @return A character string that holds a UUID.
#' @keywords internal
uuid_generator <- function() {
  return(uuid::UUIDgenerate())
}

#' Generate a hash of an object
#'
#' `hash_it()` is an internal function. It creates a hash of an object with the
#' digest package.
#'
#' @param x The object to hash.
#' @return A character string that holds the hash.
#' @keywords internal
hash_it <- function(x) {
  return(digest::digest(x))
}

# The environment that a plan stores with an unqualified `fn_name`, so that the
# name resolves where the caller wrote it. A qualified name, or a call from the
# global environment, needs none.
fn_name_env <- function(fn_name, env) {
  if (
    is.null(fn_name) ||
      length(grep("::", fn_name)) > 0 ||
      identical(env, globalenv())
  ) {
    return(NULL)
  }
  return(env)
}

# The function that a data source or an analysis names in `fn_name`.
find_fn <- function(fn_name, fn_env) {
  if (is.null(fn_env)) {
    fn_env <- globalenv()
  }
  return(get_anything(fn_name, envir = fn_env, mode = "function"))
}

# The helpers below hold the logic of Plan methods. The static-checks gate
# measures the cyclomatic complexity of the whole R6Class() call, so logic that
# branches lives here rather than in the class.

# Load every data source that add_data() stored, in the order added.
load_data_sources <- function(sources) {
  retval <- list()
  for (x in sources) {
    if (!is.null(x[["fn"]])) {
      retval[[x[["name"]]]] <- x[["fn"]]()
    }
    if (!is.null(x[["fn_name"]])) {
      retval[[x[["name"]]]] <- do.call(
        find_fn(x[["fn_name"]], x[["fn_env"]]),
        list()
      )
    }
    if (!is.null(x[["direct"]])) {
      retval[[x[["name"]]]] <- x[["direct"]]
    }
  }
  return(retval)
}

# The sykdomspulsen core data function returns one element with this name,
# which holds a named list of datasets. Return that named list instead.
unwrap_go_up_one_level <- function(retval) {
  key <- "data__________go_up_one_level"
  if (length(retval) != 1 || !key %in% names(retval)) {
    return(retval)
  }
  inner <- retval[[key]]
  if (
    !inherits(inner, "list") ||
      (is.null(names(inner)) && length(inner) != 0)
  ) {
    stop(
      "you are not passing a named list as the return from the data function",
      call. = FALSE
    )
  }
  return(inner)
}

# The element that get_data() adds under the name "hash".
data_hashes <- function(retval) {
  hash <- list()
  hash$current <- digest::digest(retval, algo = "spookyhash")
  hash$current_elements <- list()
  for (i in names(retval)) {
    hash$current_elements[[i]] <- digest::digest(
      retval[[i]],
      algo = "spookyhash"
    )
  }
  return(hash)
}

# One argset as a one-row data frame, for get_argsets_as_dt().
argset_as_row <- function(x) {
  if (identical(x[["argset"]], list())) {
    return(data.frame(index_analysis = 1))
  }
  return(data.frame(t(x[["argset"]])))
}

# An argset for add_analysis(). It takes the method-level fn, and the
# method-level fn_name unless the argset names its own.
with_action_fn <- function(argset, fn, fn_name) {
  argset$fn <- fn
  if (!"fn_name" %in% names(argset)) {
    argset$fn_name <- fn_name
  }
  return(argset)
}

# One analysis with its action function replaced.
set_fn_fields <- function(analysis, fn, fn_name, fn_env) {
  analysis$fn <- fn
  analysis$fn_name <- fn_name
  analysis$fn_env <- fn_env
  return(analysis)
}

# The action function of one analysis.
analysis_fn <- function(analysis) {
  has_fn <- !is.null(analysis[["fn"]])
  has_fn_name <- !is.null(analysis[["fn_name"]])
  if (!has_fn && !has_fn_name) {
    stop("Both fn and fn_name are NULL", call. = FALSE)
  }
  if (has_fn && has_fn_name) {
    stop("Both fn and fn_name are set. Set only one of them.", call. = FALSE)
  }
  if (has_fn) {
    return(analysis[["fn"]])
  }
  return(find_fn(analysis[["fn_name"]], analysis[["fn_env"]]))
}

# Run one analysis, as get_analysis() returns it. A function given as fn gets
# the argset by position and every argument in `...`. A function given as
# fn_name gets `data` and `argset` by name, and `...` only when it has more
# than two formal arguments.
run_analysis <- function(analysis, data, ...) {
  fn <- analysis_fn(analysis)
  num_args <- length(formals(fn))
  if (num_args < 2) {
    stop("fn must have at least two arguments", call. = FALSE)
  }
  if (!is.null(analysis[["fn"]])) {
    return(fn(data = data, analysis[["argset"]], ...))
  }

  args <- list()
  args[["data"]] <- data
  args[["argset"]] <- analysis[["argset"]]
  if (num_args > 2) {
    dots <- list(...)
    for (i in seq_along(dots)) {
      args[[names(dots)[i]]] <- dots[[i]]
    }
  }
  return(do.call(what = fn, args = args))
}

# Whether run_all() makes its own progress bar: the plan is verbose and the
# caller set no bar.
wants_default_progress <- function(verbose, pb_progress, pb_progressor) {
  return(verbose && is.null(pb_progress) && is.null(pb_progressor))
}

# The progress bar that run_all() shows without foreach.
new_progress_bar <- function(total) {
  pb <- progress::progress_bar$new(
    format = paste0(
      "[:bar] :current/:total (:percent) in :elapsedfull, eta: :eta",
      ifelse(interactive(), "", "\n")
    ),
    clear = FALSE,
    total = total
  )
  pb$tick(0)
  return(pb)
}

# Advance the progress bar that the plan holds, if it is verbose.
tick_progress <- function(verbose, pb_progress, pb_progressor) {
  if (verbose && !is.null(pb_progress)) {
    pb_progress$tick()
  }
  if (verbose && !is.null(pb_progressor)) {
    pb_progressor()
  }
  return(invisible(NULL))
}

# Whether run_all() uses foreach. NULL means: use it when a parallel backend
# with more than one worker is registered and progressr is installed.
decide_use_foreach <- function(use_foreach) {
  if (!is.null(use_foreach)) {
    return(use_foreach)
  }
  return(
    foreach::getDoParWorkers() != 1 &&
      requireNamespace("progressr", quietly = TRUE)
  )
}

#' R6 Class for Planning and Executing Analyses
#'
#' @description
#' The `Plan` class organizes and runs multiple analyses on one or more datasets.
#' It enforces a structured approach to analysis in three ways.
#'
#' 1. **Data Management**:
#'    - Load data once and reuse it across analyses
#'    - Keep data cleaning separate from analysis
#'    - Track data changes with a hash
#'
#' 2. **Analysis Structure**:
#'    - Require all analyses to use the same data sources
#'    - Standardize analysis functions to accept only `data` and `argset` parameters
#'    - Organize analyses into clear, maintainable plans
#'
#' 3. **Execution Control**:
#'    - Support both single-function and multi-function analysis plans
#'    - Run analyses either in sequence or in parallel
#'    - Supply built-in debugging tools
#'
#' @details
#' The framework uses three main concepts:
#'
#' - **Argset**: A named list that holds a set of arguments for an analysis
#' - **Analysis**: A combination of one argset and one action function
#' - **Plan**: A container that holds one data pull and a list of analyses
#'
#' @seealso `vignette("plnr")` for an introduction to argsets, analyses and
#' plans. See `vignette("adding_analyses")` for worked single-function and
#' multi-function plans.
#'
#' @import data.table
#' @import R6
#' @import foreach
#' @importFrom progress progress_bar
#' @export
Plan <- R6::R6Class(
  "Plan",
  portable = FALSE,
  cloneable = TRUE,
  public = list(
    #' @field analyses List of analyses. Each analysis holds one argset and one
    #' action function.
    analyses = list(),

    #' @description Create a new Plan instance.
    #' @param verbose Logical. Whether to show verbose output. The default is
    #' `TRUE` in interactive mode, or when `config$force_verbose` is `TRUE`.
    #' @param use_foreach Logical. Whether to use foreach for parallel
    #' processing. `NULL` lets the program decide. `FALSE` uses a loop. `TRUE`
    #' uses foreach.
    #' @return A new Plan instance.
    initialize = function(
      verbose = interactive() | config$force_verbose,
      use_foreach = FALSE
    ) {
      private$verbose <- verbose
      private$use_foreach <- use_foreach
      return(invisible(self))
    },

    #' @description Add a new dataset to the plan.
    #' @param name Character string. The name of the dataset.
    #' @param fn Optional. A function that returns the dataset.
    #' @param fn_name Optional. A character string that names a function that
    #' returns the dataset.
    #' @param direct Optional. The dataset object itself.
    #' @return NULL. The method changes the plan in place.
    #' @examples
    #' p <- plnr::Plan$new()
    #'
    #' # Add data using a function
    #' data_fn <- function() { return(plnr::nor_covid19_cases_by_time_location) }
    #' p$add_data("data_1", fn = data_fn)
    #'
    #' # Add data using a function name
    #' p$add_data("data_2", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #'
    #' # Add data directly
    #' p$add_data("data_3", direct = plnr::nor_covid19_cases_by_time_location)
    #'
    #' # View added data
    #' p$get_data()
    add_data = function(name, fn = NULL, fn_name = NULL, direct = NULL) {
      env <- parent.frame()
      stopifnot(is.null(fn) | is.function(fn))
      stopifnot(is.null(fn_name) | is.character(fn_name))

      source <- list(
        fn = fn,
        fn_name = fn_name,
        direct = direct,
        name = name,
        fn_env = fn_name_env(fn_name, env)
      )
      private$data[[length(private$data) + 1]] <<- source
      return(invisible(source))
    },

    #' @description Add a new argset to the plan.
    #' @param name Character string. The name of the argset. The default is a
    #' UUID.
    #' @param ... Named arguments that make up the argset.
    #' @return NULL. The method changes the plan in place.
    #' @examples
    #' p <- plnr::Plan$new()
    #'
    #' # Add argsets with different arguments
    #' p$add_argset("argset_1", var_1 = 3, var_b = "hello")
    #' p$add_argset("argset_2", var_1 = 8, var_c = "hello2")
    #'
    #' # View added argsets
    #' p$get_argsets_as_dt()
    add_argset = function(name = uuid::UUIDgenerate(), ...) {
      if (is.null(analyses[[name]])) {
        analyses[[name]] <<- list()
      }

      dots <- list(...)
      analyses[[name]][["argset"]] <<- dots
      return(invisible(dots))
    },

    #' @description Add multiple argsets from a data frame.
    #' @param df A data frame. Each row is one new argset.
    #' @return NULL. The method changes the plan in place.
    #' @examples
    #' p <- plnr::Plan$new()
    #'
    #' # Create data frame of argsets
    #' batch_argset_df <- data.frame(
    #'   name = c("a", "b", "c"),
    #'   var_1 = c(1, 2, 3),
    #'   var_2 = c("i", "j", "k")
    #' )
    #'
    #' # Add argsets from data frame
    #' p$add_argset_from_df(batch_argset_df)
    #'
    #' # View added argsets
    #' p$get_argsets_as_dt()
    add_argset_from_df = function(df) {
      df <- as.data.frame(df)
      lapply(seq_len(nrow(df)), function(i) do.call(self$add_argset, df[i, ]))
      return(invisible(NULL))
    },

    #' @description Add multiple argsets from a list.
    #' @param l A list of lists. Each inner list is one new argset.
    #' @return NULL. The method changes the plan in place.
    #' @examples
    #' p <- plnr::Plan$new()
    #'
    #' # Create list of argsets
    #' batch_argset_list <- list(
    #'   list(name = "a", var_1 = 1, var_2 = "i"),
    #'   list(name = "b", var_1 = 2, var_2 = "j"),
    #'   list(name = "c", var_1 = 3, var_2 = "k")
    #' )
    #'
    #' # Add argsets from list
    #' p$add_argset_from_list(batch_argset_list)
    #'
    #' # View added argsets
    #' p$get_argsets_as_dt()
    add_argset_from_list = function(l) {
      lapply(l, function(argset) do.call(self$add_argset, argset))
      return(invisible(NULL))
    },

    #' @description Add a new analysis to the plan.
    #' @param name Character string. The name of the analysis. The default is a
    #' UUID.
    #' @param fn Optional. The function to use for the analysis.
    #' @param fn_name Optional. A character string that names the function to
    #' use.
    #' @param ... Further arguments to add to the argset.
    #' @return NULL. The method changes the plan in place.
    #' @examples
    #' p <- plnr::Plan$new()
    #'
    #' # Add example data
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #'
    #' # Add analysis
    #' p$add_analysis(
    #'   name = "analysis_1",
    #'   fn_name = "plnr::example_action_fn"
    #' )
    #'
    #' # View argsets and run analysis
    #' p$get_argsets_as_dt()
    #' p$run_one("analysis_1")
    add_analysis = function(
      name = uuid::UUIDgenerate(),
      fn = NULL,
      fn_name = NULL,
      ...
    ) {
      add_one <- private$analysis_adder(parent.frame())
      return(add_one(name = name, fn = fn, fn_name = fn_name, ...))
    },

    #' @description Add multiple analyses from a data frame.
    #' @param fn Optional. The function to use for all analyses.
    #' @param fn_name Optional. A character string that names the function to
    #' use.
    #' @param df A data frame. Each row is one new analysis.
    #' @return NULL. The method changes the plan in place.
    #' @examples
    #' p <- plnr::Plan$new()
    #'
    #' # Add example data
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #'
    #' # Create data frame of analyses
    #' batch_argset_df <- data.frame(
    #'   name = c("a", "b", "c"),
    #'   var_1 = c(1, 2, 3),
    #'   var_2 = c("i", "j", "k")
    #' )
    #'
    #' # Add analyses from data frame
    #' p$add_analysis_from_df(
    #'   fn_name = "plnr::example_action_fn",
    #'   df = batch_argset_df
    #' )
    #'
    #' # View argsets and run example
    #' p$get_argsets_as_dt()
    #' p$run_one(1)
    add_analysis_from_df = function(fn = NULL, fn_name = NULL, df) {
      stopifnot(is.null(fn) | is.function(fn) | "fn_name" %in% names(df))
      stopifnot(is.null(fn_name) | is.character(fn_name))

      add_one <- private$analysis_adder(parent.frame())
      df <- as.data.frame(df)
      lapply(seq_len(nrow(df)), function(i) {
        return(do.call(add_one, with_action_fn(df[i, ], fn, fn_name)))
      })
      return(invisible(NULL))
    },

    #' @description Add multiple analyses from a list.
    #' @param fn Optional. The function to use for all analyses.
    #' @param fn_name Optional. A character string that names the function to
    #' use.
    #' @param l A list of lists. Each inner list is one new analysis.
    #' @return NULL. The method changes the plan in place.
    #' @examples
    #' p <- plnr::Plan$new()
    #'
    #' # Add example data
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #'
    #' # Create list of analyses
    #' batch_argset_list <- list(
    #'   list(name = "analysis_1", var_1 = 1, var_2 = "i"),
    #'   list(name = "analysis_2", var_1 = 2, var_2 = "j"),
    #'   list(name = "analysis_3", var_1 = 3, var_2 = "k")
    #' )
    #'
    #' # Add analyses from list
    #' p$add_analysis_from_list(
    #'   fn_name = "plnr::example_action_fn",
    #'   l = batch_argset_list
    #' )
    #'
    #' # View argsets and run example
    #' p$get_argsets_as_dt()
    #' p$run_one("analysis_1")
    add_analysis_from_list = function(fn = NULL, fn_name = NULL, l) {
      stopifnot(is.null(fn) | is.function(fn))
      stopifnot(is.null(fn_name) | is.character(fn_name))

      add_one <- private$analysis_adder(parent.frame())
      lapply(l, function(argset) {
        return(do.call(add_one, with_action_fn(argset, fn, fn_name)))
      })
      return(invisible(NULL))
    },

    #' @description Apply one action function to all the argsets.
    #' @param fn Action function.
    #' @param fn_name Action function name.
    #' p <- plnr::Plan$new()
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #' batch_argset_list <- list(
    #'   list(name = "analysis_1", var_1 = 1, var_2 = "i"),
    #'   list(name = "analysis_2", var_1 = 2, var_2 = "j"),
    #'   list(name = "analysis_3", var_1 = 3, var_2 = "k")
    #' )
    #' p$add_argset_from_list(
    #'   fn_name = "plnr::example_action_fn",
    #'   l = batch_argset_list
    #' )
    #' p$get_argsets_as_dt()
    #' p$apply_action_fn_to_all_argsets(fn_name = "plnr::example_action_fn")
    #' p$run_one("analysis_1")
    apply_action_fn_to_all_argsets = function(fn = NULL, fn_name = NULL) {
      return(private$set_action_fn(fn, fn_name, parent.frame()))
    },
    #' @description Deprecated. Use `apply_action_fn_to_all_argsets()` instead.
    #' @param fn Action function.
    #' @param fn_name Action function name.
    apply_analysis_fn_to_all = function(fn = NULL, fn_name = NULL) {
      .Deprecated("apply_action_fn_to_all_argsets")
      return(private$set_action_fn(fn, fn_name, parent.frame()))
    },

    #' @description
    #' Number of analyses in the plan.
    x_length = function() {
      return(length(self$analyses))
    },

    #' @description
    #' Generate a regular sequence from 1 to the number of analyses in the plan.
    x_seq_along = function() {
      return(base::seq_along(self$analyses))
    },

    #' @description
    #' Set an internal progress bar.
    #' @param pb Progress bar.
    set_progress = function(pb) {
      private$pb_progress <- pb
      return(invisible(pb))
    },

    #' @description
    #' Set an internal progressor progress bar.
    #' @param pb progressor progress bar.
    set_progressor = function(pb) {
      private$pb_progressor <- pb
      return(invisible(pb))
    },

    #' @description
    #' Set the `verbose` flag.
    #' @param x Boolean.
    set_verbose = function(x) {
      private$verbose <- x
      return(invisible(x))
    },

    #' @description
    #' Set the `use_foreach` flag.
    #' @param x Boolean.
    set_use_foreach = function(x) {
      private$use_foreach <- x
      return(invisible(x))
    },

    #' @description
    #' Extract the data added with `add_data()` and return it as a named list.
    #' @return
    #' A named list. Most elements come from `add_data()`.
    #'
    #' One extra named element is called 'hash'. 'hash' holds the data hashes of
    #' particular datasets and variables. `digest::digest()` calculates them
    #' with the 'spookyhash' algorithm.
    #'
    #' 'hash' holds two named elements:
    #' - current (the hash of the entire named list)
    #' - current_elements (the hash of the named elements within the named list)
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #' p$get_data()
    get_data = function() {
      retval <- unwrap_go_up_one_level(load_data_sources(private$data))
      retval$hash <- data_hashes(retval)
      return(retval)
    },

    #' @description
    #' Extract one analysis from the plan.
    #' @param index_analysis Either an integer in `1:length(analyses)`, or a
    #' character string with the name of the analysis.
    #' @return
    #' An analysis.
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #' batch_argset_list <- list(
    #'   list(name = "analysis_1", var_1 = 1, var_2 = "i"),
    #'   list(name = "analysis_2", var_1 = 2, var_2 = "j"),
    #'   list(name = "analysis_3", var_1 = 3, var_2 = "k")
    #' )
    #' p$add_analysis_from_list(
    #'   fn_name = "plnr::example_action_fn",
    #'   l = batch_argset_list
    #' )
    #' p$get_analysis("analysis_1")
    get_analysis = function(index_analysis) {
      p <- analyses[[index_analysis]]
      p[["argset"]]$index_analysis <- index_analysis
      return(p)
    },

    #' @description
    #' Extract one argset from the plan.
    #' @param index_analysis Either an integer in `1:length(analyses)`, or a
    #' character string with the name of the analysis.
    #' @return
    #' An argset.
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #' batch_argset_list <- list(
    #'   list(name = "analysis_1", var_1 = 1, var_2 = "i"),
    #'   list(name = "analysis_2", var_1 = 2, var_2 = "j"),
    #'   list(name = "analysis_3", var_1 = 3, var_2 = "k")
    #' )
    #' p$add_analysis_from_list(
    #'   fn_name = "plnr::example_action_fn",
    #'   l = batch_argset_list
    #' )
    #' p$get_argset("analysis_1")
    get_argset = function(index_analysis) {
      p <- analyses[[index_analysis]][["argset"]]
      return(p)
    },

    #' @description
    #' Get all argsets and return them as a data.table.
    #' @return
    #' A data.table that holds all the argsets within a plan.
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #' batch_argset_list <- list(
    #'   list(name = "analysis_1", var_1 = 1, var_2 = "i"),
    #'   list(name = "analysis_2", var_1 = 2, var_2 = "j"),
    #'   list(name = "analysis_3", var_1 = 3, var_2 = "k")
    #' )
    #' p$add_analysis_from_list(
    #'   fn_name = "plnr::example_action_fn",
    #'   l = batch_argset_list
    #' )
    #' p$get_argsets_as_dt()
    get_argsets_as_dt = function() {
      retval <- lapply(analyses, argset_as_row)
      names(retval) <- NULL
      retval <- rbindlist(retval, use.names = TRUE, fill = TRUE)
      retval[, name_analysis := names(analyses)]
      retval[, index_analysis := seq_len(.N)]

      setcolorder(retval, c("name_analysis", "index_analysis"))
      data.table::shouldPrint(retval)

      return(retval)
    },

    #' @description
    #' Run one analysis. You supply the data.
    #' @param index_analysis Either an integer in `1:length(analyses)`, or a
    #' character string with the name of the analysis.
    #' @param data A named list. You normally get it from `p$get_data()`.
    #' @param ... Not used.
    #' @return
    #' The value that the action function returns.
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #' batch_argset_list <- list(
    #'   list(name = "analysis_1", var_1 = 1, var_2 = "i"),
    #'   list(name = "analysis_2", var_1 = 2, var_2 = "j"),
    #'   list(name = "analysis_3", var_1 = 3, var_2 = "k")
    #' )
    #' p$add_analysis_from_list(
    #'   fn_name = "plnr::example_action_fn",
    #'   l = batch_argset_list
    #' )
    #' data <- p$get_data()
    #' p$run_one_with_data("analysis_1", data)
    run_one_with_data = function(index_analysis, data, ...) {
      return(run_analysis(get_analysis(index_analysis), data, ...))
    },

    #' @description
    #' Run one analysis. The method gets the data from `self$get_data()`.
    #' @param index_analysis Either an integer in `1:length(analyses)`, or a
    #' character string with the name of the analysis.
    #' @param ... Not used.
    #' @return
    #' The value that the action function returns.
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #' batch_argset_list <- list(
    #'   list(name = "analysis_1", var_1 = 1, var_2 = "i"),
    #'   list(name = "analysis_2", var_1 = 2, var_2 = "j"),
    #'   list(name = "analysis_3", var_1 = 3, var_2 = "k")
    #' )
    #' p$add_analysis_from_list(
    #'   fn_name = "plnr::example_action_fn",
    #'   l = batch_argset_list
    #' )
    #' p$run_one("analysis_1")
    run_one = function(index_analysis, ...) {
      data <- get_data()
      return(run_one_with_data(
        index_analysis = index_analysis,
        data = data,
        ...
      ))
    },

    #' @description
    #' Run all analyses. You supply the data.
    #' @param data A named list. You normally get it from `p$get_data()`.
    #' @param ... Not used.
    #' @param .plnr.options A list of options for plnr. plnr does not pass it to
    #' the action function. `chunk_size` goes to foreach as
    #' `.options.future = list(chunk.size = chunk_size)`, which only a
    #' future-based backend such as doFuture reads. The default is 1.
    #' @return
    #' A list. Each element is the value that the action function returns.
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #' batch_argset_list <- list(
    #'   list(name = "analysis_1", var_1 = 1, var_2 = "i"),
    #'   list(name = "analysis_2", var_1 = 2, var_2 = "j"),
    #'   list(name = "analysis_3", var_1 = 3, var_2 = "k")
    #' )
    #' p$add_analysis_from_list(
    #'   fn_name = "plnr::example_action_fn",
    #'   l = batch_argset_list
    #' )
    #' data <- p$get_data()
    #' p$run_all_with_data(data)
    run_all_with_data = function(data, ..., .plnr.options = NULL) {
      chunk_size <- .plnr.options[["chunk_size"]]
      if (is.null(chunk_size)) {
        chunk_size <- 1
      }
      if (private$use_foreach_decision()) {
        return(invisible(private$run_all_foreach(data, chunk_size, ...)))
      }
      return(invisible(private$run_all_loop(data, ...)))
    },

    #' @description
    #' Run all analyses. The method gets the data from `self$get_data()`.
    #' @param ... Not used.
    #' @return
    #' A list. Each element is the value that the action function returns.
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #' batch_argset_list <- list(
    #'   list(name = "analysis_1", var_1 = 1, var_2 = "i"),
    #'   list(name = "analysis_2", var_1 = 2, var_2 = "j"),
    #'   list(name = "analysis_3", var_1 = 3, var_2 = "k")
    #' )
    #' p$add_analysis_from_list(
    #'   fn_name = "plnr::example_action_fn",
    #'   l = batch_argset_list
    #' )
    #' p$run_all()
    run_all = function(...) {
      data <- get_data()
      return(run_all_with_data(data = data, ...))
    },

    #' @description
    #' Run all analyses and show a progress bar. The method gets the data from
    #' `self$get_data()`.
    #' @param ... Not used.
    #' @return
    #' A list. Each element is the value that the action function returns.
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #' batch_argset_list <- list(
    #'   list(name = "analysis_1", var_1 = 1, var_2 = "i"),
    #'   list(name = "analysis_2", var_1 = 2, var_2 = "j"),
    #'   list(name = "analysis_3", var_1 = 3, var_2 = "k")
    #' )
    #' p$add_analysis_from_list(
    #'   fn_name = "plnr::example_action_fn",
    #'   l = batch_argset_list
    #' )
    #' p$run_all_progress()
    run_all_progress = function(...) {
      return(progressr::with_progress(
        {
          run_all(...)
        },
        delay_stdout = FALSE
      ))
    },

    #' @description
    #' Run all analyses in parallel. The method gets the data from
    #' `self$get_data()`.
    #'
    #' This method works only on linux computers. It uses `pbmcapply` as the
    #' parallel backend.
    #' @param mc.cores The number of cores to use.
    #' @param ... Not used.
    #' @return
    #' A list. Each element is the value that the action function returns.
    #' @importFrom pbmcapply pbmclapply
    run_all_parallel = function(mc.cores = getOption("mc.cores", 2L), ...) {
      data <- self$get_data()
      return(invisible(pbmcapply::pbmclapply(
        self$x_seq_along(),
        function(x) {
          options(mc.cores = 1)
          return(tryCatch(
            {
              return(self$run_one_with_data(
                index_analysis = x,
                data = data,
                ...
              ))
            },
            error = function(e) {
              system(sprintf(
                'echo "\n%s\n"',
                paste0(
                  "Error in index ",
                  x,
                  ":\n\u2193\u2193\u2193\u2193\u2193\u2193\u2193\u2193\n",
                  e$message,
                  "\n********",
                  collapse = ""
                )
              ))
              stop()
            }
          ))
        },
        ignore.interactive = TRUE,
        mc.cores = mc.cores,
        mc.style = "ETA",
        mc.substyle = 2
      )))
    }
  ),
  private = list(
    verbose = FALSE,
    use_foreach = FALSE,
    pb_progress = NULL,
    pb_progressor = NULL,

    data = list(),

    # A function with the formals of add_analysis(). It stores each analysis
    # with the environment where the caller wrote its fn_name.
    analysis_adder = function(env) {
      force(env)
      return(function(
        name = uuid::UUIDgenerate(),
        fn = NULL,
        fn_name = NULL,
        ...
      ) {
        stopifnot(is.null(fn) | is.function(fn))
        stopifnot(is.null(fn_name) | is.character(fn_name))

        dots <- list(...)
        analyses[[name]] <<- list(
          fn = fn,
          fn_name = fn_name,
          fn_env = fn_name_env(fn_name, env)
        )
        analyses[[name]][["argset"]] <<- dots
        return(invisible(dots))
      })
    },

    set_action_fn = function(fn, fn_name, env) {
      stopifnot(is.null(fn) | is.function(fn))
      stopifnot(is.null(fn_name) | is.character(fn_name))

      analyses <<- lapply(
        analyses,
        set_fn_fields,
        fn = fn,
        fn_name = fn_name,
        fn_env = fn_name_env(fn_name, env)
      )
      return(invisible(NULL))
    },

    use_foreach_decision = function() {
      return(decide_use_foreach(private$use_foreach))
    },

    run_all_loop = function(data, ...) {
      if (
        wants_default_progress(
          private$verbose,
          private$pb_progress,
          private$pb_progressor
        )
      ) {
        private$pb_progress <- new_progress_bar(self$x_length())
        on.exit(private$pb_progress <- NULL)
      }
      retval <- vector("list", length = self$x_length())
      for (i in self$x_seq_along()) {
        tick_progress(
          private$verbose,
          private$pb_progress,
          private$pb_progressor
        )
        retval[[i]] <- run_one_with_data(index_analysis = i, data = data, ...)
        gc(FALSE)
      }
      return(retval)
    },

    run_all_foreach = function(data, chunk_size, ...) {
      if (
        wants_default_progress(
          private$verbose,
          private$pb_progress,
          private$pb_progressor
        )
      ) {
        progressr::handlers(progressr::handler_progress(
          format = "[:bar] :current/:total (:percent) in :elapsedfull, eta: :eta\n",
          clear = FALSE
        ))
        private$pb_progressor <- progressr::progressor(
          steps = self$x_length()
        )
        on.exit(private$pb_progressor <- NULL)
      }
      retval <- foreach(
        i = self$x_seq_along(),
        .options.future = list(chunk.size = chunk_size)
      ) %dopar%
        {
          tick_progress(
            private$verbose,
            private$pb_progress,
            private$pb_progressor
          )
          retval_i <- run_one_with_data(index_analysis = i, data = data, ...)
          gc(FALSE)
          retval_i
        }
      return(retval)
    }
  )
)
