#' Set plnr options
#'
#' `set_opts()` sets options for the whole package.
#'
#' @param force_verbose Logical. `TRUE` makes every [Plan] that you create
#' afterwards verbose, even in a non-interactive session. The default is
#' `FALSE`.
#' @return `force_verbose`, invisibly.
#' @examples
#' set_opts(force_verbose = TRUE)
#' set_opts(force_verbose = FALSE)
#' @family plan helpers
#' @seealso `vignette("plnr")` for the concepts.
#' @export
set_opts <- function(force_verbose = FALSE) {
  config$force_verbose <- force_verbose
  return(invisible(force_verbose))
}
