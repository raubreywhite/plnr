#' Print what an action function receives
#'
#' `example_action_fn()` is an example action function. It prints the names of
#' the datasets in `data` and the names of the elements in `argset`.
#'
#' @param data A named list of datasets, as a [Plan] passes it.
#' @param argset A named list of arguments for one analysis.
#' @return `names(argset)`, invisibly.
#' @examples
#' p <- plnr::Plan$new()
#' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
#' p$add_analysis_from_list(
#'   fn_name = "plnr::example_action_fn",
#'   l = list(
#'     list(name = "analysis_1", var_1 = 1),
#'     list(name = "analysis_2", var_1 = 2)
#'   )
#' )
#' p$run_one("analysis_1")
#' @family example and test functions
#' @seealso `vignette("plnr")` for what an action function is.
#' @export
example_action_fn <- function(data, argset) {
  print("Data given:")
  print(names(data))
  print("Argset given:")
  print(names(argset))
  return(invisible(names(argset)))
}

#' Return 1, whatever the input
#'
#' `test_action_fn()` is a placeholder action function. It ignores its arguments.
#'
#' @param data Not used.
#' @param argset Not used.
#' @return The number 1, a double.
#' @examples
#' test_action_fn(data = list(), argset = list())
#'
#' p <- plnr::Plan$new()
#' p$add_data(name = "deaths", direct = data.frame(deaths = 1:4, year = 2001:2004))
#' p$add_analysis(name = "analysis_1", fn_name = "plnr::test_action_fn")
#' p$run_one("analysis_1")
#' @family example and test functions
#' @seealso `vignette("plnr")` for what an action function is.
#' @export
test_action_fn <- function(data, argset) {
  return(1)
}

#' Generate a UUID
#'
#' `uuid_generator()` is internal. It returns `uuid::UUIDgenerate()`.
#'
#' @return A character string that holds a UUID.
#' @keywords internal
uuid_generator <- function() {
  return(uuid::UUIDgenerate())
}

#' Hash an object
#'
#' `hash_it()` is internal. It returns `digest::digest(x)`.
#'
#' @param x The object to hash.
#' @return A character string that holds the hash.
#' @keywords internal
hash_it <- function(x) {
  return(digest::digest(x))
}

# plnr calls gc(FALSE) after an analysis only when this many seconds of
# elapsed time passed since its last collection. One call took about 46 ms
# with data.table and ggplot2 loaded, so the calls take at most about 5% of
# the run time.
gc_interval_seconds <- 1

# The elapsed time of the last collection that plnr made in this process.
# NULL until the first check, which only records the time. Each process has
# its own copy, so each foreach or forked worker throttles itself.
gc_state <- new.env(parent = emptyenv())
gc_state$last <- NULL

# The elapsed time in seconds. Tests replace this function with a counter.
gc_clock <- function() {
  return(proc.time()[["elapsed"]])
}

# Call gc(FALSE) if gc_interval_seconds passed since the last collection that
# plnr made in this process. Returns TRUE if it collected.
gc_if_due <- function() {
  now <- gc_clock()
  if (is.null(gc_state$last)) {
    gc_state$last <- now
    return(invisible(FALSE))
  }
  if (now - gc_state$last < gc_interval_seconds) {
    return(invisible(FALSE))
  }
  gc(FALSE)
  gc_state$last <- now
  return(invisible(TRUE))
}

# The environment that a plan stores with `fn_name`: the local environment
# where the name resolves now, in step 2 of get_anything(). NULL when the name
# is qualified, or resolves only globally or in plnr. The plan stores nothing
# else, so it keeps no unrelated object of the calling frame alive.
fn_name_env <- function(fn_name, env) {
  if (is.null(fn_name) || length(grep("::", fn_name)) > 0) {
    return(NULL)
  }
  return(find_local_env(fn_name, env, mode = "function"))
}

# The function that a data source or an analysis names in `fn_name`.
find_fn <- function(fn_name, fn_env) {
  if (is.null(fn_env)) {
    fn_env <- globalenv()
  }
  return(get_anything(fn_name, envir = fn_env, mode = "function"))
}

#' Plan and run analyses
#'
#' @description
#' A `Plan` holds data sources and analyses, and runs the analyses on the data.
#' An analysis is one argset plus one action function.
#'
#' @details
#' An argset is a named list of arguments for one analysis. When an analysis
#' runs, its argset also holds `index_analysis`: the position or name that ran
#' it.
#'
#' An action function MUST take the data as its first argument and the argset as
#' its second. It MAY take further arguments. The run methods pass their `...`
#' to it in one of two ways:
#' - A function given as `fn` gets the argset by position, and every argument in
#'   `...`.
#' - A function given as `fn_name` gets `data` and `argset` by name. It gets
#'   `...` only when it has more than two formal arguments.
#'
#' [get_anything()] finds the function that `fn_name` names when the analysis
#' runs. If the name resolved in a local environment when you set `fn_name`,
#' the plan stores that environment and looks there first.
#'
#' @return `Plan$new()` returns a new `Plan` object.
#' @family plan helpers
#' @seealso `vignette("plnr")` for the concepts. `vignette("adding_analyses")`
#' for worked single-function and multi-function plans.
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
    #' @field analyses A named list with one element for each analysis. Each
    #' element holds `argset` and, once set, `fn`, `fn_name` and `fn_env`.
    analyses = list(),

    #' @description Create a new plan.
    #' @param verbose Logical. `TRUE` makes `run_all()` show progress. The default
    #' is `TRUE` in an interactive session, or after
    #' `set_opts(force_verbose = TRUE)`.
    #' @param use_foreach Logical or `NULL`. `TRUE` makes `run_all()` use foreach,
    #' and `FALSE` a loop. `NULL` uses foreach when a backend with more than one
    #' worker is registered and progressr is installed. The default is `FALSE`.
    #' @return A new `Plan` object.
    initialize = function(
      verbose = interactive() | config$force_verbose,
      use_foreach = FALSE
    ) {
      private$verbose <- verbose
      private$use_foreach <- use_foreach
      return(invisible(use_foreach))
    },

    #' @description Add a data source. `get_data()` loads every data source.
    #' Give one of `fn`, `fn_name` and `direct`. If you give more, `direct`
    #' wins over `fn_name`, and `fn_name` wins over `fn`.
    #' @details
    #' The key fields of a data function are its arguments without a default,
    #' other than `...`. A data function without a key field makes one dataset
    #' for the whole run: the plan calls it once, with no arguments. A data
    #' function with key fields makes keyed data:
    #' - For each analysis, the plan calls the function with the key fields of
    #'   the argset, by name. Arguments with a default keep their default, and
    #'   `...` gets nothing.
    #' - The plan keeps the dataset under the values of the key fields, and
    #'   gives the same object to each analysis with the same values.
    #' - If an argset does not have a key field, the run stops before the first
    #'   analysis.
    #' - Two values are the same only when they have the same type and the same
    #'   value. So `1` and `1L` are different, `NA` and `NA_character_` are
    #'   different, and `NULL` is a value.
    #' - When no remaining analysis of the run needs a kept dataset, the plan
    #'   drops it.
    #'
    #' The plan calls a keyed data function exactly once for each distinct set
    #' of values, in `run_all()` with or without foreach and in
    #' `run_all_parallel()`. `run_one()` and `get_data()` call it once for each
    #' call. A parallel run puts the analyses that share a value of any keyed
    #' data source in one group, and runs each group in one task. So a run has
    #' at most one busy worker for each group:
    #' - With one keyed data source, there is one group for each set of values.
    #' - With one source keyed by `scenario` and one by `scenario` and `sim`,
    #'   there is one group for each scenario.
    #' - With one source keyed by `scenario` and one by `sim`, all analyses are
    #'   in one group, and the run is sequential.
    #'
    #' On a PSOCK worker, a data function finds the objects of the environment
    #' where you defined it. It does not find the objects of the global
    #' environment of the main process. Pass such an object as an argset field,
    #' or define the function inside another function.
    #' @param name Character string. The name of the dataset in the list that
    #' `get_data()` returns.
    #' @param fn Optional. A function that returns the dataset.
    #' @param fn_name Optional. The name of such a function, as a character string.
    #' `"pkg::fn"` also works.
    #' @param direct Optional. The dataset itself.
    #' @return The stored data source, invisibly: a list that holds `fn`,
    #' `fn_name`, `direct`, `name` and `fn_env`.
    #' @examples
    #' p <- plnr::Plan$new()
    #' data_fn <- function() {
    #'   return(plnr::nor_covid19_cases_by_time_location)
    #' }
    #' p$add_data("data_1", fn = data_fn)
    #' p$add_data("data_2", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #' p$add_data("data_3", direct = plnr::nor_covid19_cases_by_time_location)
    #' names(p$get_data())
    #'
    #' # Keyed data: one simulated dataset for each value of `sim`
    #' p <- plnr::Plan$new()
    #' p$add_data("sim_data", fn = function(sim) {
    #'   set.seed(sim)
    #'   return(rnorm(5))
    #' })
    #' p$add_argset_from_list(plnr::expand_list(sim = 1:2, stat = c("mean", "max")))
    #' p$apply_action_fn_to_all_argsets(fn = function(data, argset) {
    #'   return(match.fun(argset$stat)(data$sim_data))
    #' })
    #' unlist(p$run_all())
    add_data = function(name, fn = NULL, fn_name = NULL, direct = NULL) {
      stopifnot(is.null(fn) | is.function(fn))
      stopifnot(is.null(fn_name) | is.character(fn_name))

      source <- list(
        fn = fn,
        fn_name = fn_name,
        direct = direct,
        name = name,
        fn_env = fn_name_env(fn_name, parent.frame())
      )
      private$data[[length(private$data) + 1]] <<- source
      return(invisible(source))
    },

    #' @description Add an argset: an analysis that has no action function yet.
    #' If an analysis with this name exists, `add_argset()` replaces its argset and
    #' keeps its action function.
    #' @param name Character string. The name of the analysis. The default is a
    #' UUID.
    #' @param ... Named arguments. They make up the argset.
    #' @return The argset, invisibly.
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_argset("argset_1", var_1 = 3, var_b = "hello")
    #' p$add_argset("argset_2", var_1 = 8, var_c = "hello2")
    #' p$get_argsets_as_dt()
    add_argset = function(name = uuid::UUIDgenerate(), ...) {
      if (is.null(analyses[[name]])) {
        analyses[[name]] <<- list()
      }

      dots <- list(...)
      analyses[[name]][["argset"]] <<- dots
      return(invisible(dots))
    },

    #' @description Add one argset for each row of a data frame.
    #' @param df A data frame. Each row is one argset. A column `name` names the
    #' analyses.
    #' @return `NULL`, invisibly.
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_argset_from_df(data.frame(name = c("a", "b"), var_1 = c(1, 2)))
    #' p$get_argsets_as_dt()
    add_argset_from_df = function(df) {
      df <- as.data.frame(df)
      for (i in seq_len(nrow(df))) {
        argset <- df[i, ]
        do.call(self$add_argset, argset)
      }
      return(invisible(NULL))
    },

    #' @description Add one argset for each element of a list.
    #' @param l A list of named lists. Each inner list is one argset. An element
    #' `name` names the analysis.
    #' @return `NULL`, invisibly.
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_argset_from_list(plnr::expand_list(var_1 = 1:2, var_2 = c("i", "j")))
    #' p$get_argsets_as_dt()
    add_argset_from_list = function(l) {
      for (i in seq_along(l)) {
        argset <- l[[i]]
        do.call(self$add_argset, argset)
      }
      return(invisible(NULL))
    },

    #' @description Add an analysis: one argset and one action function. If an
    #' analysis with this name exists, `add_analysis()` replaces it.
    #' @param name Character string. The name of the analysis. The default is a
    #' UUID.
    #' @param fn Optional. The action function.
    #' @param fn_name Optional. The name of the action function, as a character
    #' string. `"pkg::fn"` also works. Give `fn` or `fn_name`, not both.
    #' @param ... Named arguments. They make up the argset.
    #' @return The argset, invisibly.
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #' p$add_analysis(name = "analysis_1", fn_name = "plnr::example_action_fn")
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

    #' @description Add one analysis for each row of a data frame.
    #' @param fn Optional. The action function of every analysis.
    #' @param fn_name Optional. The name of the action function of every analysis.
    #' A column `fn_name` in `df` overrides it.
    #' @param df A data frame. Each row is one argset. A column `name` names the
    #' analyses.
    #' @return `NULL`, invisibly.
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #' p$add_analysis_from_df(
    #'   fn_name = "plnr::example_action_fn",
    #'   df = data.frame(name = c("a", "b"), var_1 = c(1, 2))
    #' )
    #' p$run_one("a")
    add_analysis_from_df = function(fn = NULL, fn_name = NULL, df) {
      stopifnot(is.null(fn) | is.function(fn) | "fn_name" %in% names(df))
      stopifnot(is.null(fn_name) | is.character(fn_name))

      add_one <- private$analysis_adder(parent.frame())
      df <- as.data.frame(df)
      for (i in seq_len(nrow(df))) {
        argset <- df[i, ]
        argset$fn <- fn
        if (!"fn_name" %in% names(df)) {
          argset$fn_name <- fn_name
        }
        do.call(add_one, argset)
      }
      return(invisible(NULL))
    },

    #' @description Add one analysis for each element of a list.
    #' @param fn Optional. The action function of every analysis.
    #' @param fn_name Optional. The name of the action function of every analysis.
    #' An element `fn_name` in an inner list overrides it.
    #' @param l A list of named lists. Each inner list is one argset. An element
    #' `name` names the analysis.
    #' @return `NULL`, invisibly.
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #' p$add_analysis_from_list(
    #'   fn_name = "plnr::example_action_fn",
    #'   l = list(
    #'     list(name = "analysis_1", var_1 = 1),
    #'     list(name = "analysis_2", var_1 = 2)
    #'   )
    #' )
    #' p$run_one("analysis_1")
    add_analysis_from_list = function(fn = NULL, fn_name = NULL, l) {
      stopifnot(is.null(fn) | is.function(fn))
      stopifnot(is.null(fn_name) | is.character(fn_name))

      add_one <- private$analysis_adder(parent.frame())
      for (i in seq_along(l)) {
        argset <- l[[i]]
        argset$fn <- fn
        if (!"fn_name" %in% names(argset)) {
          argset$fn_name <- fn_name
        }
        do.call(add_one, argset)
      }
      return(invisible(NULL))
    },

    #' @description Give every analysis in the plan the same action function. It
    #' replaces any action function that an analysis already has.
    #' @param fn Optional. The action function.
    #' @param fn_name Optional. The name of the action function, as a character
    #' string.
    #' @return `NULL`, invisibly.
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #' p$add_argset_from_list(list(
    #'   list(name = "analysis_1", var_1 = 1),
    #'   list(name = "analysis_2", var_1 = 2)
    #' ))
    #' p$apply_action_fn_to_all_argsets(fn_name = "plnr::example_action_fn")
    #' p$run_one("analysis_1")
    apply_action_fn_to_all_argsets = function(fn = NULL, fn_name = NULL) {
      return(private$set_action_fn(fn, fn_name, parent.frame()))
    },
    #' @description Deprecated. Use `apply_action_fn_to_all_argsets()`.
    #' @param fn Optional. The action function.
    #' @param fn_name Optional. The name of the action function.
    #' @return `NULL`, invisibly.
    apply_analysis_fn_to_all = function(fn = NULL, fn_name = NULL) {
      .Deprecated("apply_action_fn_to_all_argsets")
      return(private$set_action_fn(fn, fn_name, parent.frame()))
    },

    #' @description Count the analyses in the plan.
    #' @return An integer.
    x_length = function() {
      return(length(self$analyses))
    },

    #' @description Get the positions of the analyses, `seq_along(analyses)`.
    #' @return An integer vector.
    x_seq_along = function() {
      return(base::seq_along(self$analyses))
    },

    #' @description Set a progress bar that `run_all()` ticks once for each
    #' analysis.
    #' @param pb An object with a `tick()` method, such as one from
    #' `progress::progress_bar$new()`.
    #' @return `pb`, invisibly.
    set_progress = function(pb) {
      private$pb_progress <- pb
      return(invisible(pb))
    },

    #' @description Set a progressr progressor that `run_all()` calls once for each
    #' analysis.
    #' @param pb A function from `progressr::progressor()`.
    #' @return `pb`, invisibly.
    set_progressor = function(pb) {
      private$pb_progressor <- pb
      return(invisible(pb))
    },

    #' @description Set `verbose`, which `new()` describes.
    #' @param x Logical.
    #' @return `x`, invisibly.
    set_verbose = function(x) {
      private$verbose <- x
      return(invisible(x))
    },

    #' @description Set `use_foreach`, which `new()` describes.
    #' @param x Logical or `NULL`.
    #' @return `x`, invisibly.
    set_use_foreach = function(x) {
      private$use_foreach <- x
      return(invisible(x))
    },

    #' @description Load every data source, and return the datasets as a named
    #' list. For a plan with keyed data, give an analysis: `get_data()` then
    #' returns the list that the action function of that analysis gets.
    #' @param index_analysis Optional. The position of an analysis, or its name.
    #' A plan with keyed data needs it, and `get_data()` without it stops with
    #' an error. A plan without keyed data does not use it.
    #' @return A named list with one element for each dataset, and an element
    #' `hash`. `hash$current_elements` holds one spookyhash digest for each
    #' dataset. Without keyed data, `hash$current` is the digest of the
    #' datasets. With keyed data, it is the digest of `hash$current_elements`,
    #' so that each dataset is hashed once. plnr does not read these digests.
    #'
    #' If the only data source is `data__________go_up_one_level` and it returns
    #' a named list, that list holds the datasets.
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #' str(p$get_data(), max.level = 1)
    #'
    #' # Keyed data: give the analysis
    #' p <- plnr::Plan$new()
    #' p$add_data("d", fn = function(scenario) paste("data for", scenario))
    #' p$add_argset(name = "a", scenario = "null")
    #' p$get_data("a")$d
    get_data = function(index_analysis = NULL) {
      sources <- private$resolve_data()
      if (length(sources$keyed) == 0) {
        return(finish_data(sources$values))
      }
      if (is.null(index_analysis)) {
        stop(
          "The data ",
          paste0("'", names(sources$keyed), "'", collapse = ", "),
          " depends on the argset. Give get_data() an analysis, ",
          "for example get_data(1).",
          call. = FALSE
        )
      }
      return(private$keyed_data(
        keyed_state(sources),
        sources,
        index_analysis,
        private$keyed_keys(sources, index_analysis)
      ))
    },

    #' @description Get one analysis.
    #' @param index_analysis The position of the analysis, or its name.
    #' @return The analysis, as `analyses` holds it. Its argset also holds
    #' `index_analysis`.
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #' p$add_analysis_from_list(
    #'   fn_name = "plnr::example_action_fn",
    #'   l = list(
    #'     list(name = "analysis_1", var_1 = 1),
    #'     list(name = "analysis_2", var_1 = 2)
    #'   )
    #' )
    #' p$get_analysis("analysis_1")
    get_analysis = function(index_analysis) {
      p <- analyses[[index_analysis]]
      p[["argset"]]$index_analysis <- index_analysis
      return(p)
    },

    #' @description Get the argset of one analysis.
    #' @param index_analysis The position of the analysis, or its name.
    #' @return The argset, a named list.
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #' p$add_analysis_from_list(
    #'   fn_name = "plnr::example_action_fn",
    #'   l = list(
    #'     list(name = "analysis_1", var_1 = 1),
    #'     list(name = "analysis_2", var_1 = 2)
    #'   )
    #' )
    #' p$get_argset("analysis_1")
    get_argset = function(index_analysis) {
      p <- analyses[[index_analysis]][["argset"]]
      return(p)
    },

    #' @description Get every argset as one row of a data.table.
    #' @return A data.table. Its first columns are `name_analysis` and
    #' `index_analysis`, and it has one more column for each argset element.
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #' p$add_analysis_from_list(
    #'   fn_name = "plnr::example_action_fn",
    #'   l = list(
    #'     list(name = "analysis_1", var_1 = 1),
    #'     list(name = "analysis_2", var_1 = 2)
    #'   )
    #' )
    #' p$get_argsets_as_dt()
    get_argsets_as_dt = function() {
      retval <- lapply(analyses, function(x) {
        if (identical(x[["argset"]], list())) {
          return(data.frame(index_analysis = 1))
        } else {
          return(data.frame(t(x[["argset"]])))
        }
      })
      names(retval) <- NULL
      retval <- rbindlist(retval, use.names = TRUE, fill = TRUE)
      retval[, name_analysis := names(analyses)]
      retval[, index_analysis := seq_len(.N)]

      setcolorder(retval, c("name_analysis", "index_analysis"))
      data.table::shouldPrint(retval)

      return(retval)
    },

    #' @description Run one analysis on data that you give it. The plan calls
    #' no data function, also no keyed data function.
    #' @param index_analysis The position of the analysis, or its name.
    #' @param data A named list of datasets, normally from `get_data()`.
    #' @param ... Further arguments for the action function. See 'Details'.
    #' @return The value that the action function returns.
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #' p$add_analysis_from_list(
    #'   fn_name = "plnr::example_action_fn",
    #'   l = list(
    #'     list(name = "analysis_1", var_1 = 1),
    #'     list(name = "analysis_2", var_1 = 2)
    #'   )
    #' )
    #' data <- p$get_data()
    #' p$run_one_with_data("analysis_1", data)
    run_one_with_data = function(index_analysis, data, ...) {
      p <- get_analysis(index_analysis)

      if (is.null(p[["fn"]]) & is.null(p[["fn_name"]])) {
        stop("Both fn and fn_name are NULL", call. = FALSE)
      } else if (!is.null(p[["fn"]]) & is.null(p[["fn_name"]])) {
        # use fn
        num_args <- length(formals(p[["fn"]]))
      } else if (is.null(p[["fn"]]) & !is.null(p[["fn_name"]])) {
        # use fn_name
        num_args <- length(formals(find_fn(p[["fn_name"]], p[["fn_env"]])))
      }

      args <- list()
      args[["data"]] <- data
      args[["argset"]] <- p[["argset"]]

      if (num_args < 2) {
        stop("fn must have at least two arguments", call. = FALSE)
      } else if (num_args == 2) {
        # dont do anything
      } else {
        dots <- list(...)
        for (i in seq_along(dots)) {
          n <- names(dots)[i]
          args[[n]] <- dots[[i]]
        }
      }

      # actually run it
      if (!is.null(p[["fn"]]) & is.null(p[["fn_name"]])) {
        # use fn
        retval <- p$fn(
          data = data,
          p[["argset"]],
          ...
        )
      } else if (is.null(p[["fn"]]) & !is.null(p[["fn_name"]])) {
        # use fn_name
        retval <- do.call(
          what = find_fn(p[["fn_name"]], p[["fn_env"]]),
          args = args
        )
      }

      return(retval)
    },

    #' @description Run one analysis. `run_one()` loads the data for that
    #' analysis with `get_data()` each time you call it.
    #' @param index_analysis The position of the analysis, or its name.
    #' @param ... Further arguments for the action function. See 'Details'.
    #' @return The value that the action function returns.
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #' p$add_analysis_from_list(
    #'   fn_name = "plnr::example_action_fn",
    #'   l = list(
    #'     list(name = "analysis_1", var_1 = 1),
    #'     list(name = "analysis_2", var_1 = 2)
    #'   )
    #' )
    #' p$run_one("analysis_1")
    run_one = function(index_analysis, ...) {
      data <- get_data(index_analysis)
      return(run_one_with_data(
        index_analysis = index_analysis,
        data = data,
        ...
      ))
    },

    #' @description Run every analysis on data that you give it. Every analysis
    #' gets `data`. The plan calls no data function, also no keyed data function.
    #' @param data A named list of datasets, normally from `get_data()`.
    #' @param ... Further arguments for the action function. See 'Details'.
    #' @param .plnr.options A list of options for plnr. The action function
    #' does not get it. `chunk_size` goes to foreach as
    #' `.options.future = list(chunk.size = chunk_size)`. Only a future-based
    #' backend, such as doFuture, reads it. The default is 1.
    #' @return A list, invisibly. Element `i` is the value that the action function
    #' of analysis `i` returns. Without foreach, a `NULL` value at the end of the
    #' plan adds no element, so the list can be shorter than the plan.
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #' p$add_analysis_from_list(
    #'   fn_name = "plnr::example_action_fn",
    #'   l = list(
    #'     list(name = "analysis_1", var_1 = 1),
    #'     list(name = "analysis_2", var_1 = 2)
    #'   )
    #' )
    #' data <- p$get_data()
    #' results <- p$run_all_with_data(data)
    run_all_with_data = function(data, ..., .plnr.options = NULL) {
      chunk_size <- .plnr.options[["chunk_size"]]
      if (is.null(chunk_size)) {
        chunk_size <- 1
      }

      retval <- vector("list", length = self$x_length())
      if (!private$use_foreach_decision()) {
        # running not in parallel
        if (
          private$verbose &
            is.null(private$pb_progress) &
            is.null(private$pb_progressor)
        ) {
          private$pb_progress <- progress::progress_bar$new(
            format = paste0(
              "[:bar] :current/:total (:percent) in :elapsedfull, eta: :eta",
              ifelse(interactive(), "", "\n")
            ),
            clear = FALSE,
            total = self$x_length()
          )
          private$pb_progress$tick(0)
          on.exit(private$pb_progress <- NULL)
        }

        for (i in self$x_seq_along()) {
          if (private$verbose & !is.null(private$pb_progress)) {
            private$pb_progress$tick()
          }
          if (private$verbose & !is.null(private$pb_progressor)) {
            if (interactive()) {
              private$pb_progressor()
            } else {
              private$pb_progressor()
            }
          }
          retval[[i]] <- run_one_with_data(index_analysis = i, data = data, ...)
          gc_if_due()
        }
      } else {
        # running in parallel
        if (
          private$verbose &
            is.null(private$pb_progress) &
            is.null(private$pb_progressor)
        ) {
          # progressr is in Suggests. Without it, run without a progress bar.
          if (requireNamespace("progressr", quietly = TRUE)) {
            progressr::handlers(progressr::handler_progress(
              format = "[:bar] :current/:total (:percent) in :elapsedfull, eta: :eta\n",
              clear = FALSE
            ))
            private$pb_progressor <- progressr::progressor(
              steps = self$x_length()
            )
            on.exit(private$pb_progressor <- NULL)
          }
        }

        # A PSOCK worker gets only the variables of this frame. The body also
        # needs private and run_one_with_data, which live in the object.
        # The body returns the value of the analysis, not that of gc().
        retval <- foreach(
          i = self$x_seq_along(),
          .export = c("private", "run_one_with_data"),
          .options.future = list(chunk.size = chunk_size)
        ) %dopar%
          {
            if (private$verbose & !is.null(private$pb_progress)) {
              private$pb_progress$tick()
            }
            if (private$verbose & !is.null(private$pb_progressor)) {
              if (interactive()) {
                private$pb_progressor()
              } else {
                private$pb_progressor()
              }
            }
            retval_i <- run_one_with_data(index_analysis = i, data = data, ...)
            private$gc_check()
            retval_i
          }
      }

      return(invisible(retval))
    },

    #' @description Run every analysis. `run_all()` loads the data once with
    #' `get_data()`, and passes it to every analysis. `add_data()` gives how
    #' often it calls a keyed data function.
    #' @param ... Further arguments for the action function, and `.plnr.options`.
    #' `run_all_with_data()` describes both.
    #' @return A list, invisibly, as `run_all_with_data()` returns it.
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #' p$add_analysis_from_list(
    #'   fn_name = "plnr::example_action_fn",
    #'   l = list(
    #'     list(name = "analysis_1", var_1 = 1),
    #'     list(name = "analysis_2", var_1 = 2)
    #'   )
    #' )
    #' results <- p$run_all()
    run_all = function(...) {
      sources <- private$resolve_data()
      if (length(sources$keyed) > 0) {
        return(private$run_all_keyed(sources, ...))
      }
      data <- finish_data(sources$values)
      return(run_all_with_data(data = data, ...))
    },

    #' @description Run every analysis, as `run_all()` does, inside
    #' `progressr::with_progress()`. A progressr progressor then shows progress.
    #' It stops with an error when the progressr package is not installed.
    #' @param ... Passed to `run_all()`.
    #' @return A list, invisibly, as `run_all()` returns it.
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #' p$add_analysis_from_list(
    #'   fn_name = "plnr::example_action_fn",
    #'   l = list(
    #'     list(name = "analysis_1", var_1 = 1),
    #'     list(name = "analysis_2", var_1 = 2)
    #'   )
    #' )
    #' if (requireNamespace("progressr", quietly = TRUE)) {
    #'   results <- p$run_all_progress()
    #' }
    run_all_progress = function(...) {
      if (!requireNamespace("progressr", quietly = TRUE)) {
        stop("run_all_progress() needs the progressr package.", call. = FALSE)
      }
      return(progressr::with_progress(
        {
          run_all(...)
        },
        delay_stdout = FALSE
      ))
    },

    #' @description Run every analysis in forked processes with
    #' `pbmcapply::pbmclapply()`, which shows a progress bar. It loads the data once
    #' with `get_data()`. Windows cannot fork. There, pbmcapply sets `mc.cores` to
    #' 1, warns, and runs the analyses in sequence.
    #'
    #' With keyed data, each task is one group of analyses, as `add_data()`
    #' describes, and the progress bar counts groups. An error gives a
    #' `try-error` to its own analysis only. An error in a keyed data function
    #' goes to each analysis that needs that dataset. Without keyed data, an
    #' error gives a `try-error` to each analysis that ran in the same process.
    #' @param mc.cores The number of processes.
    #' @param ... Further arguments for the action function. See 'Details'.
    #' @return A list, invisibly. Element `i` is the value that the action function
    #' of analysis `i` returns.
    #' @importFrom pbmcapply pbmclapply
    run_all_parallel = function(mc.cores = getOption("mc.cores", 2L), ...) {
      sources <- private$resolve_data()
      if (length(sources$keyed) > 0) {
        return(private$run_all_parallel_keyed(sources, mc.cores, ...))
      }
      data <- finish_data(sources$values)
      raw <- pbmcapply::pbmclapply(
        self$x_seq_along(),
        function(x) {
          options(mc.cores = 1)
          catch_result <- tryCatch(
            {
              return(self$run_one_with_data(
                index_analysis = x,
                data = data,
                ...
              ))
            },
            error = function(e) {
              echo_parallel_error(x, e)
              stop()
            }
          )
          return(catch_result)
        },
        ignore.interactive = TRUE,
        mc.cores = mc.cores,
        mc.style = "ETA",
        mc.substyle = 2
      )
      return(invisible(raw))
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

      fn_env <- fn_name_env(fn_name, env)
      for (i in seq_along(analyses)) {
        analyses[[i]]$fn <<- fn
        analyses[[i]]$fn_name <<- fn_name
        analyses[[i]]$fn_env <<- fn_env
      }
      return(invisible(NULL))
    },

    # The foreach body calls gc_if_due() through private, which a PSOCK
    # worker receives.
    gc_check = function() {
      return(gc_if_due())
    },

    use_foreach_decision = function() {
      if (!is.null(private$use_foreach)) {
        return(private$use_foreach)
      } else {
        if (
          foreach::getDoParWorkers() == 1 ||
            !requireNamespace("progressr", quietly = TRUE)
        ) {
          return(FALSE)
        } else {
          return(TRUE)
        }
      }
    },

    # Keyed data: a data function with arguments. See add_data().

    # Load every data source, in order, as get_data() always did. A keyed data
    # function is not called: its dataset holds a placeholder until an
    # analysis needs it. `keyed` holds the keyed sources that the data list
    # still holds at the end, by name.
    resolve_data = function() {
      retval <- list()
      keyed <- list()
      for (i in seq_along(private$data)) {
        x <- private$data[[i]]
        if (!is.null(x$fn)) {
          if (length(key_fields(x$fn)) == 0) {
            retval[[x$name]] <- x$fn()
          } else {
            retval[[x$name]] <- keyed_placeholder()
            keyed[[x$name]] <- keyed_source(x$fn, x$name)
          }
        }
        if (!is.null(x$fn_name)) {
          fn <- find_fn(x$fn_name, x$fn_env)
          if (length(key_fields(fn)) == 0) {
            retval[[x$name]] <- do.call(fn, list())
          } else {
            retval[[x$name]] <- keyed_placeholder()
            keyed[[x$name]] <- keyed_source(fn, x$name)
          }
        }
        if (!is.null(x$direct)) {
          retval[[x$name]] <- x$direct
        }
      }
      still_keyed <- vapply(
        names(keyed),
        function(n) return(inherits(retval[[n]], keyed_class)),
        logical(1)
      )
      return(list(values = retval, keyed = keyed[still_keyed]))
    },

    # The argset of one analysis, as its action function gets it.
    keyed_argset = function(index_analysis) {
      if (!has_analysis(analyses, index_analysis)) {
        stop(
          "The plan has no analysis ",
          paste(format(index_analysis), collapse = ", "),
          ".",
          call. = FALSE
        )
      }
      return(get_analysis(index_analysis)[["argset"]])
    },

    # One cache key for each keyed data source, for one analysis.
    keyed_keys = function(sources, index_analysis) {
      argset <- private$keyed_argset(index_analysis)
      label <- index_analysis
      if (!is.character(label) && !is.null(names(analyses))) {
        label <- names(analyses)[[index_analysis]]
      }
      keys <- vapply(
        sources$keyed,
        function(source) {
          absent <- setdiff(source$fields, names(argset))
          if (length(absent) > 0) {
            stop(
              "Analysis '",
              label,
              "' has no argset field '",
              absent[[1]],
              "', which the data '",
              source$name,
              "' needs.",
              call. = FALSE
            )
          }
          return(paste(
            vapply(argset[source$fields], key_of_value, character(1)),
            collapse = "|"
          ))
        },
        character(1)
      )
      return(keys)
    },

    # The data list for one analysis. A keyed dataset comes from the cache in
    # `state`. On a miss, the plan calls the keyed data function and stores
    # the dataset and its digest.
    keyed_data = function(state, sources, index_analysis, keys) {
      values <- sources$values
      entries <- list()
      argset <- NULL
      for (name in names(sources$keyed)) {
        key <- keys[[name]]
        cache <- state$cache[[name]]
        if (!exists(key, envir = cache, inherits = FALSE)) {
          if (is.null(argset)) {
            argset <- private$keyed_argset(index_analysis)
          }
          source <- sources$keyed[[name]]
          entry <- new.env(parent = emptyenv())
          assign(key, entry, envir = cache)
          # A failed call is kept too, so the plan calls the function once
          # for each key, and each analysis that needs it gets the error.
          withCallingHandlers(
            entry$value <- do.call(
              source$fn,
              argset[source$fields],
              quote = TRUE
            ),
            error = function(e) {
              entry$error <- e
              return(invisible(NULL))
            }
          )
          entry$digest <- digest::digest(entry$value, algo = "spookyhash")
        }
        entries[[name]] <- get(key, envir = cache, inherits = FALSE)
        if (!is.null(entries[[name]]$error)) {
          stop(entries[[name]]$error)
        }
        values[[name]] <- entries[[name]]$value
      }
      return(finish_keyed_data(values, entries, state))
    },

    # Show progress for one analysis, as run_all_with_data() does.
    keyed_tick = function() {
      if (isTRUE(private$verbose) && !is.null(private$pb_progress)) {
        private$pb_progress$tick()
      }
      if (isTRUE(private$verbose) && !is.null(private$pb_progressor)) {
        private$pb_progressor()
      }
      return(invisible(NULL))
    },

    # run_all() for a plan with keyed data. It checks every argset before any
    # analysis runs.
    run_all_keyed = function(sources, ..., .plnr.options = NULL) {
      chunk_size <- .plnr.options[["chunk_size"]]
      if (is.null(chunk_size)) {
        chunk_size <- 1
      }
      keys <- lapply(self$x_seq_along(), function(i) {
        return(private$keyed_keys(sources, i))
      })
      if (private$use_foreach_decision()) {
        return(private$run_keyed_foreach(sources, keys, chunk_size, ...))
      }
      return(private$run_keyed_loop(sources, keys, ...))
    },

    # The sequential run. The cache drops a dataset after the last analysis
    # that needs it.
    run_keyed_loop = function(sources, keys, ...) {
      if (
        isTRUE(private$verbose) &&
          is.null(private$pb_progress) &&
          is.null(private$pb_progressor)
      ) {
        private$pb_progress <- progress::progress_bar$new(
          format = paste0(
            "[:bar] :current/:total (:percent) in :elapsedfull, eta: :eta",
            ifelse(interactive(), "", "\n")
          ),
          clear = FALSE,
          total = self$x_length()
        )
        private$pb_progress$tick(0)
        on.exit(private$pb_progress <- NULL)
      }
      retval <- private$run_keyed_analyses(
        sources,
        keys,
        self$x_seq_along(),
        FALSE,
        ...
      )
      return(invisible(retval))
    },

    # The foreach run. Each task is one group of analyses that share keys, so
    # a keyed data function runs once for each key.
    run_keyed_foreach = function(sources, keys, chunk_size, ...) {
      groups <- keyed_groups(keys)
      if (
        isTRUE(private$verbose) &&
          is.null(private$pb_progress) &&
          is.null(private$pb_progressor) &&
          requireNamespace("progressr", quietly = TRUE)
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
      # A PSOCK worker gets only the variables of this frame, and private.
      results <- foreach(
        group = groups,
        .export = "private",
        .options.future = list(chunk.size = chunk_size)
      ) %dopar%
        {
          private$run_keyed_analyses(sources, keys, group, FALSE, ...)
        }
      return(invisible(spread_groups(results, groups, self$x_length())))
    },

    # Run the analyses `idx` in order, with one cache. The cache drops a
    # dataset after the last analysis in `idx` that needs it. Each result,
    # also NULL, goes to its own position. With `catch_errors`, an error
    # becomes the try-error of its own analysis.
    run_keyed_analyses = function(sources, keys, idx, catch_errors, ...) {
      state <- keyed_state(sources, keys[idx])
      retval <- vector("list", length = length(idx))
      for (j in seq_along(idx)) {
        i <- idx[[j]]
        if (catch_errors) {
          retval[j] <- list(tryCatch(
            private$keyed_run_one(state, sources, keys, i, ...),
            error = function(e) {
              echo_parallel_error(i, e)
              return(try(stop(e), silent = TRUE))
            }
          ))
        } else {
          private$keyed_tick()
          retval[j] <- list(private$keyed_run_one(state, sources, keys, i, ...))
        }
        keyed_release(state, keys[[i]])
        gc_if_due()
      }
      return(retval)
    },

    # One analysis. Its data list lives only in this frame.
    keyed_run_one = function(state, sources, keys, i, ...) {
      data <- private$keyed_data(state, sources, i, keys[[i]])
      return(run_one_with_data(index_analysis = i, data = data, ...))
    },

    # run_all_parallel() for a plan with keyed data: one forked task for each
    # group of analyses that share keys.
    run_all_parallel_keyed = function(sources, mc.cores, ...) {
      keys <- lapply(self$x_seq_along(), function(i) {
        return(private$keyed_keys(sources, i))
      })
      groups <- keyed_groups(keys)
      raw <- pbmcapply::pbmclapply(
        groups,
        function(group) {
          options(mc.cores = 1)
          return(private$run_keyed_analyses(sources, keys, group, TRUE, ...))
        },
        ignore.interactive = TRUE,
        mc.cores = mc.cores,
        mc.style = "ETA",
        mc.substyle = 2
      )
      return(invisible(spread_groups(raw, groups, self$x_length())))
    }
  )
)

# Load the datasets as get_data() does without keyed data: apply the
# data__________go_up_one_level rule, and add the digests.
finish_data <- function(retval) {
  retval <- go_up_one_level(retval)
  hash <- list()
  hash$current <- digest::digest(retval, algo = "spookyhash")
  hash$current_elements <- list()
  for (i in names(retval)) {
    hash$current_elements[[i]] <- digest::digest(
      retval[[i]],
      algo = "spookyhash"
    )
  }
  retval$hash <- hash
  return(retval)
}

# If the only dataset is data__________go_up_one_level, its value MUST be a
# named list, or an empty list, and that list holds the datasets.
go_up_one_level <- function(retval) {
  if (!is_go_up(retval)) {
    return(retval)
  }
  inner <- retval$data__________go_up_one_level
  if (
    inherits(inner, "list") && (!is.null(names(inner)) || length(inner) == 0)
  ) {
    return(inner)
  }
  stop(
    "you are not passing a named list as the return from the data function",
    call. = FALSE
  )
}

is_go_up <- function(retval) {
  return(
    length(retval) == 1 && "data__________go_up_one_level" %in% names(retval)
  )
}

# Print the error of one analysis in run_all_parallel(). A forked process
# writes it to the terminal.
echo_parallel_error <- function(x, e) {
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
  return(invisible(NULL))
}

# ---- keyed data ----

keyed_class <- "plnr_keyed_data_placeholder"

keyed_placeholder <- function() {
  return(structure(list(), class = keyed_class))
}

# A keyed data function, and the argset fields it needs.
keyed_source <- function(fn, name) {
  return(list(name = name, fn = fn, fields = key_fields(fn)))
}

# The key fields of a data function: its arguments without a default, other
# than `...`. A function without one is called with no arguments, as before.
key_fields <- function(fn) {
  fm <- formals(fn)
  required <- vapply(
    seq_along(fm),
    function(i) {
      return(is.name(fm[[i]]) && !nzchar(as.character(fm[[i]])))
    },
    logical(1)
  )
  return(setdiff(names(fm)[required], "..."))
}

has_analysis <- function(analyses, index_analysis) {
  if (length(index_analysis) != 1 || is.na(index_analysis)) {
    return(FALSE)
  }
  if (is.character(index_analysis)) {
    return(index_analysis %in% names(analyses))
  }
  if (is.numeric(index_analysis)) {
    return(
      index_analysis == round(index_analysis) &&
        index_analysis >= 1 &&
        index_analysis <= length(analyses)
    )
  }
  return(FALSE)
}

# The cache key of one argset value. Two values have the same key only when
# they have the same type and the same value. A scalar character, double,
# integer or logical without attributes gets an exact text key. Any other
# value gets the md5 digest of its serialisation. Each key starts with a type
# letter, and a character key holds its length, so keys joined with "|" do
# not collide.
key_of_value <- function(x) {
  if (is.null(x)) {
    return("N")
  }
  if (!is_plain_scalar(x)) {
    return(paste0("h", digest::digest(x)))
  }
  type <- typeof(x)
  if (type == "double") {
    # %a is the exact hexadecimal form. NA gives "NA", NaN gives "NaN".
    return(paste0("d", sprintf("%a", x)))
  }
  if (is.na(x)) {
    return(paste0(substr(type, 1, 1), "NA"))
  }
  if (type == "character") {
    x <- enc2utf8(x)
    return(paste0("c", nchar(x, type = "bytes"), ":", x))
  }
  return(paste0(substr(type, 1, 1), as.character(x)))
}

# A character, double, integer or logical value of length 1 without
# attributes.
is_plain_scalar <- function(x) {
  return(
    length(x) == 1 &&
      is.null(attributes(x)) &&
      typeof(x) %in% c("character", "double", "integer", "logical")
  )
}

# The cache of one run. For each keyed source, `cache` holds one entry for
# each key, and `remaining` counts the analyses that still need it. A state
# made without `keys` never drops an entry.
keyed_state <- function(sources, keys = list()) {
  state <- new.env(parent = emptyenv())
  state$cache <- list()
  state$remaining <- list()
  state$digests <- new.env(parent = emptyenv())
  state$inner <- new.env(parent = emptyenv())
  for (name in names(sources$keyed)) {
    state$cache[[name]] <- new.env(hash = TRUE, parent = emptyenv())
    counts <- table(vapply(keys, function(k) return(k[[name]]), character(1)))
    remaining <- as.list(as.integer(counts))
    names(remaining) <- names(counts)
    state$remaining[[name]] <- list2env(remaining, parent = emptyenv())
  }
  return(state)
}

# One analysis has finished. Drop each keyed dataset that no remaining
# analysis needs.
keyed_release <- function(state, keys) {
  for (name in names(keys)) {
    left <- state$remaining[[name]]
    key <- keys[[name]]
    n <- get(key, envir = left, inherits = FALSE) - 1L
    if (n == 0) {
      rm(list = key, envir = state$cache[[name]])
      rm(list = key, envir = left)
    } else {
      assign(key, n, envir = left)
    }
  }
  return(invisible(NULL))
}

# The digest of a dataset that does not depend on the argset, computed once
# for each state.
unkeyed_digest <- function(state, name, value) {
  if (!exists(name, envir = state$digests, inherits = FALSE)) {
    assign(name, digest::digest(value, algo = "spookyhash"), state$digests)
  }
  return(get(name, envir = state$digests, inherits = FALSE))
}

# The element digests of a data__________go_up_one_level list, computed once
# for each cache entry, or once for each state.
inner_digests <- function(owner, inner) {
  if (is.null(owner$inner)) {
    digests <- list()
    for (i in names(inner)) {
      digests[[i]] <- digest::digest(inner[[i]], algo = "spookyhash")
    }
    owner$inner <- digests
  }
  return(owner$inner)
}

# finish_data() for one analysis of a plan with keyed data. It reuses the
# digests in the cache, so that it hashes each dataset once.
finish_keyed_data <- function(values, entries, state) {
  if (is_go_up(values)) {
    owner <- entries[["data__________go_up_one_level"]]
    if (is.null(owner)) {
      owner <- state$inner
    }
    retval <- go_up_one_level(values)
    elements <- inner_digests(owner, retval)
  } else {
    retval <- values
    elements <- list()
    for (i in names(retval)) {
      if (i %in% names(entries)) {
        elements[[i]] <- entries[[i]]$digest
      } else {
        elements[[i]] <- unkeyed_digest(state, i, retval[[i]])
      }
    }
  }
  hash <- list()
  hash$current <- digest::digest(elements, algo = "spookyhash")
  hash$current_elements <- elements
  retval$hash <- hash
  return(retval)
}

# The analyses in connected groups. Two analyses are connected when they
# share a key in any keyed data source. So each key of each source belongs to
# exactly one group. The groups are in the order of their first analysis.
keyed_groups <- function(keys) {
  n <- length(keys)
  if (n == 0) {
    return(list())
  }
  parent <- seq_len(n)
  find <- function(i) {
    while (parent[[i]] != i) {
      i <- parent[[i]]
    }
    return(i)
  }
  for (name in names(keys[[1]])) {
    k <- vapply(keys, function(x) return(x[[name]]), character(1))
    first <- match(k, k)
    for (i in seq_len(n)) {
      a <- find(i)
      b <- find(first[[i]])
      parent[max(a, b)] <- min(a, b)
    }
  }
  roots <- vapply(seq_len(n), find, integer(1))
  groups <- split(seq_len(n), factor(roots, levels = unique(roots)))
  return(unname(groups))
}

# The results of the groups, back in the order of the analyses. A group that
# failed as a whole gives its try-error to each of its analyses.
spread_groups <- function(results, groups, n) {
  retval <- vector("list", length = n)
  for (j in seq_along(groups)) {
    if (inherits(results[[j]], "try-error")) {
      retval[groups[[j]]] <- list(results[[j]])
    } else {
      retval[groups[[j]]] <- results[[j]]
    }
  }
  return(retval)
}
