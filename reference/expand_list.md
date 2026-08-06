# Create a cross product of lists

`expand_list()` creates a cross product of multiple lists. It works like
[`tidyr::expand_grid()`](https://tidyr.tidyverse.org/reference/expand_grid.html),
but you do not need to wrap the arguments in an extra
[`list()`](https://rdrr.io/r/base/list.html). Use it to build
combinations of analysis parameters.

## Usage

``` r
expand_list(...)
```

## Arguments

- ...:

  Named arguments. Each one holds a vector or a list of values to
  combine.

## Value

A list of lists. Each inner list holds one combination of values from
the input arguments.

## See also

[Plan](https://www.rwhite.no/plnr/reference/Plan.md). Its
`add_argset_from_list()` method takes this list. See
[`vignette("adding_analyses")`](https://www.rwhite.no/plnr/articles/adding_analyses.md),
which builds argsets with `plnr::expand_list()`, then applies one action
function to all of them.

## Examples

``` r
# Create combinations of parameters
combinations <- plnr::expand_list(
  a = 1:2,
  b = c("a", "b")
)

# View the combinations
str(combinations)
#> List of 4
#>  $ :List of 2
#>   ..$ a: int 1
#>   ..$ b: chr "a"
#>  $ :List of 2
#>   ..$ a: int 1
#>   ..$ b: chr "b"
#>  $ :List of 2
#>   ..$ a: int 2
#>   ..$ b: chr "a"
#>  $ :List of 2
#>   ..$ a: int 2
#>   ..$ b: chr "b"

# Compare with tidyr::expand_grid
tidyr::expand_grid(list(
  a = 1:2,
  b = c("a", "b")
))
#> # A tibble: 2 × 1
#>   `list(a = 1:2, b = c("a", "b"))`
#>   <named list>                    
#> 1 <int [2]>                       
#> 2 <chr [2]>                       
```
