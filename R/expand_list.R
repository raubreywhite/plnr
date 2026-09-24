#' Make a list of argsets from every combination of values
#'
#' `expand_list()` returns one named list for each combination of the values
#' of its arguments. It works like `tidyr::expand_grid()`, but it returns a list
#' of lists, which `Plan$add_argset_from_list()` and
#' `Plan$add_analysis_from_list()` take.
#'
#' @param ... Named vectors or lists. Each holds the values of one argument.
#' @return A list of named lists, one for each combination. The first argument
#' varies slowest.
#' @examples
#' argsets <- plnr::expand_list(location = c("oslo", "bergen"), age = c("0-14", "15+"))
#' str(argsets)
#' @family plan helpers
#' @seealso `vignette("adding_analyses")`, which builds argsets with
#' `expand_list()`.
#' @export
expand_list <- function(...) {
  dots <- list(...)
  return(tidyr::expand_grid(!!!dots) |> purrr::pmap(list))
}
