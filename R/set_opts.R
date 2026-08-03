#' Set package configuration options
#'
#' This function allows users to configure package-wide options, such as verbosity
#' of output messages. It modifies the package's internal configuration state.
#'
#' @param force_verbose Logical, whether to force verbose output messages regardless
#' of the interactive state. Defaults to `FALSE`
#' @return NULL, modifies the package's internal configuration
#' @examples
#' # Enable verbose output
#' set_opts(force_verbose = TRUE)
#'
#' # Disable verbose output
#' set_opts(force_verbose = FALSE)
#' @seealso [Plan], whose `verbose` argument is on by default when either the
#' session is interactive or `force_verbose` is `TRUE`, and `vignette("plnr")`
#' for an introduction to the framework.
#' @export
set_opts <- function(force_verbose = FALSE) {
  config$force_verbose <- force_verbose
}
