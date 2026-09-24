#' Check whether code runs at the top level of the console
#'
#' `is_run_directly()` returns `TRUE` when you call it at the top level of the R
#' console or of an Rscript file. It returns `FALSE` inside a function, and
#' inside `source()`, `eval()` and a knitr chunk.
#'
#' Put it at the start of an action function to load `data` and `argset` while
#' you develop the function line by line. When the plan runs the function, it
#' returns `FALSE`, so the lines do nothing.
#'
#' @return `TRUE` or `FALSE`.
#' @examples
#' f <- function() {
#'   is_run_directly()
#' }
#' f()
#' @family plan helpers
#' @seealso `vignette("plnr")`, whose "Debugging" section shows the pattern.
#' @export
is_run_directly <- function() {
  return(sys.nframe() == 1)
}
