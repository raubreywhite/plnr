#' Get objects with package namespace support
#'
#' `get_anything()` extends `base::get()` to support package namespace scoping,
#' for example `"pkg::var"`. Use it for package exports and for
#' namespace-qualified objects.
#'
#' @param x Character string that names the object to get. The name is either a
#' simple object name, or a namespace-qualified name such as `"pkg::var"`.
#' @return The requested object.
#' @examples
#' # Get a namespace-qualified object
#' plnr::get_anything("plnr::nor_covid19_cases_by_time_location")
#'
#' # Get a simple object (same as base::get)
#' x <- 1
#' get_anything("x")
#' @seealso `vignette("plnr")`. Its "Function Naming" section covers the
#' `fn_name` strings that a [Plan] resolves with `get_anything()`.
#' @export
get_anything <- function(x) {
  if (length(grep("::", x)) > 0) {
    parts <- strsplit(x, "::")[[1]]
    getExportedValue(parts[1], parts[2])
  } else {
    get(x)
  }
}
