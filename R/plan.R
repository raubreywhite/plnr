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
#' [get_anything()] finds the function that `fn_name` names. It starts where
#' you called the method that set `fn_name`.
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
      return(invisible(self))
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
      lapply(seq_len(nrow(df)), function(i) do.call(self$add_argset, df[i, ]))
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
      lapply(l, function(argset) do.call(self$add_argset, argset))
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
      lapply(seq_len(nrow(df)), function(i) {
        return(do.call(add_one, with_action_fn(df[i, ], fn, fn_name)))
      })
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
      lapply(l, function(argset) {
        return(do.call(add_one, with_action_fn(argset, fn, fn_name)))
      })
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
      retval <- unwrap_go_up_one_level(load_data_sources(private$data))
      retval$hash <- data_hashes(retval)
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
      retval <- lapply(analyses, argset_as_row)
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
      return(run_analysis(get_analysis(index_analysis), data, ...))
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
      if (private$use_foreach_decision()) {
        return(invisible(private$run_all_foreach(data, chunk_size, ...)))
      }
      return(invisible(private$run_all_loop(data, ...)))
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
