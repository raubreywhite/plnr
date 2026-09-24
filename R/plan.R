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
    #' @param name Character string. The name of the dataset in the list that
    #' `get_data()` returns.
    #' @param fn Optional. A function with no arguments that returns the dataset.
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
    #' list.
    #' @return A named list with one element for each dataset, and an element
    #' `hash`. `hash$current` is the spookyhash digest of the datasets.
    #' `hash$current_elements` holds one digest for each dataset. plnr does not
    #' read these digests.
    #'
    #' If the only data source is `data__________go_up_one_level` and it returns
    #' a named list, that list holds the datasets.
    #' @examples
    #' p <- plnr::Plan$new()
    #' p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
    #' str(p$get_data(), max.level = 1)
    get_data = function() {
      retval <- list()
      for (i in seq_along(private$data)) {
        x <- private$data[[i]]
        if (!is.null(x$fn)) {
          retval[[x$name]] <- x$fn()
        }
        if (!is.null(x$fn_name)) {
          retval[[x$name]] <- do.call(find_fn(x$fn_name, x$fn_env), list())
        }
        if (!is.null(x$direct)) {
          retval[[x$name]] <- x$direct
        }
      }
      # trying to pull out what happens in sc/sykdomspulsen core
      if (length(retval) == 1) {
        if ("data__________go_up_one_level" %in% names(retval)) {
          # make sure it's a list
          if (inherits(retval$data__________go_up_one_level, "list")) {
            # check that if it has content, it is named
            if (
              !is.null(names(retval$data__________go_up_one_level)) |
                length(retval$data__________go_up_one_level) == 0
            ) {
              # this is what happens in sc/sykdomspulsen core
              retval <- retval$data__________go_up_one_level
            } else {
              stop(
                "you are not passing a named list as the return from the data function",
                call. = FALSE
              )
            }
          } else {
            stop(
              "you are not passing a named list as the return from the data function",
              call. = FALSE
            )
          }
        }
      }
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

    #' @description Run one analysis on data that you give it.
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

    #' @description Run one analysis. `run_one()` loads the data with `get_data()`
    #' each time you call it.
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
      data <- get_data()
      return(run_one_with_data(
        index_analysis = index_analysis,
        data = data,
        ...
      ))
    },

    #' @description Run every analysis on data that you give it.
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
          gc(FALSE)
        }
      } else {
        # running in parallel
        if (
          private$verbose &
            is.null(private$pb_progress) &
            is.null(private$pb_progressor)
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
            gc(FALSE)
            retval_i
          }
      }

      return(invisible(retval))
    },

    #' @description Run every analysis. `run_all()` loads the data once with
    #' `get_data()`, and passes it to every analysis.
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
      data <- get_data()
      return(run_all_with_data(data = data, ...))
    },

    #' @description Run every analysis, as `run_all()` does, inside
    #' `progressr::with_progress()`. A progressr progressor then shows progress.
    #' It needs the progressr package.
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
    #' @param mc.cores The number of processes.
    #' @param ... Further arguments for the action function. See 'Details'.
    #' @return A list, invisibly. Element `i` is the value that the action function
    #' of analysis `i` returns.
    #' @importFrom pbmcapply pbmclapply
    run_all_parallel = function(mc.cores = getOption("mc.cores", 2L), ...) {
      data <- self$get_data()
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
    }
  )
)
