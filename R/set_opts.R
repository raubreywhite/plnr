#' Set package configuration options
#'
#' `set_opts()` sets package-wide options, such as the verbosity of output
#' messages. It changes the internal configuration state of the package.
#'
#' @param force_verbose Logical. Whether to force verbose output messages,
#' whatever the interactive state is. The default is `FALSE`.
#' @return NULL. `set_opts()` changes the internal configuration of the package.
#' @examples
#' # Enable verbose output
#' set_opts(force_verbose = TRUE)
#'
#' # Disable verbose output
#' set_opts(force_verbose = FALSE)
#' @seealso [Plan]. Its `verbose` argument is on by default when the session is
#' interactive, or when `force_verbose` is `TRUE`. See `vignette("plnr")` for an
#' introduction to the framework.
#' @export
set_opts <- function(force_verbose = FALSE) {
  config$force_verbose <- force_verbose
}
