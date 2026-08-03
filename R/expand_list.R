#' Create a cross product of lists
#'
#' This function creates a cross product of multiple lists, similar to `tidyr::expand_grid()`
#' but with a more convenient interface that doesn't require wrapping arguments in an
#' extra `list()`. It's useful for generating combinations of parameters for analysis.
#'
#' @param ... Named arguments, each containing a vector or list of values to combine
#' @return A list of lists, where each inner list contains one combination of values
#' from the input arguments
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
#' @seealso [Plan], whose `add_argset_from_list()` method consumes this list,
#' and `vignette("adding_analyses")`, which builds argsets with
#' `plnr::expand_list()` before applying an action function to all of them.
#' @export
expand_list <- function(...) {
  dots <- list(...)
  tidyr::expand_grid(!!!dots) |> purrr::pmap(list)
}
