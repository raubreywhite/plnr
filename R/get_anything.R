#' Find an object by name
#'
#' `get_anything()` returns the object that a name refers to. It also accepts a
#' namespace-qualified name such as `"pkg::fn"`, which [Plan] allows for
#' `fn_name`.
#'
#' `get_anything()` looks in this order and returns the first match:
#' 1. For `"pkg::name"`, the object that package `pkg` exports. It looks
#'    nowhere else.
#' 2. The environments from `envir` up to, but not including, the first global
#'    environment or package namespace above it.
#' 3. The global environment, then the search path.
#' 4. The plnr namespace, then the packages that plnr imports.
#'
#' Because step 4 is last, a function of yours wins over a plnr function with
#' the same name.
#'
#' @param x Character string. The name of the object.
#' @param envir The environment where step 2 starts. The default is the
#' environment that calls `get_anything()`.
#' @param mode The type of object to find, as in [base::get()]. [Plan] uses
#' `"function"`.
#' @return The object that `x` names. `get_anything()` stops with an error when
#' no object matches.
#' @examples
#' # Get a namespace-qualified object
#' head(plnr::get_anything("plnr::nor_covid19_cases_by_time_location"))
#'
#' # Get an object from the calling environment
#' f <- function() {
#'   x <- 1
#'   get_anything("x")
#' }
#' f()
#' @seealso `vignette("plnr")`. Its "Function Naming" section covers the
#' `fn_name` strings that a [Plan] resolves with `get_anything()`.
#' @export
get_anything <- function(x, envir = parent.frame(), mode = "any") {
  if (length(grep("::", x)) > 0) {
    parts <- strsplit(x, "::")[[1]]
    return(getExportedValue(parts[1], parts[2]))
  }

  # Step 2: the local environments, nearest first. topenv() with emptyenv()
  # ignores the topLevelEnvironment option, which sys.source() sets.
  env <- envir
  top <- topenv(envir, emptyenv())
  while (!identical(env, top) && !identical(env, emptyenv())) {
    if (exists(x, envir = env, mode = mode, inherits = FALSE)) {
      return(get(x, envir = env, mode = mode, inherits = FALSE))
    }
    env <- parent.env(env)
  }

  # Step 3: the global environment and the search path.
  if (exists(x, envir = globalenv(), mode = mode)) {
    return(get(x, envir = globalenv(), mode = mode))
  }

  # Step 4: the plnr namespace and its imports.
  return(get(x, envir = asNamespace("plnr"), mode = mode))
}
