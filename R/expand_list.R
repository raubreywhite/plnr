#' Create a cross product of lists
#'
#' `expand_list()` creates a cross product of multiple lists. It works like
#' `tidyr::expand_grid()`, but you do not need to wrap the arguments in an extra
#' `list()`. Use it to build combinations of analysis parameters.
#'
#' @param ... Named arguments. Each one holds a vector or a list of values to
#' combine.
#' @return A list of lists. Each inner list holds one combination of values from
#' the input arguments.
#' @examples
#' # Create combinations of parameters
#' combinations <- plnr::expand_list(
#'   a = 1:2,
#'   b = c("a", "b")
#' )
#'
#' # View the combinations
#' str(combinations)
#'
#' # Compare with tidyr::expand_grid
#' tidyr::expand_grid(list(
#'   a = 1:2,
#'   b = c("a", "b")
#' ))
#' @seealso [Plan]. Its `add_argset_from_list()` method takes this list. See
#' `vignette("adding_analyses")`, which builds argsets with
#' `plnr::expand_list()`, then applies one action function to all of them.
#' @export
expand_list <- function(...) {
  dots <- list(...)
  tidyr::expand_grid(!!!dots) |> purrr::pmap(list)
}
