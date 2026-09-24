# Make a list of argsets from every combination of values

`expand_list()` returns one named list for each combination of the
values of its arguments. It works like
[`tidyr::expand_grid()`](https://tidyr.tidyverse.org/reference/expand_grid.html),
but it returns a list of lists, which `Plan$add_argset_from_list()` and
`Plan$add_analysis_from_list()` take.

## Usage

``` r
expand_list(...)
```

## Arguments

- ...:

  Named vectors or lists. Each holds the values of one argument.

## Value

A list of named lists, one for each combination. The first argument
varies slowest.

## See also

[`vignette("adding_analyses")`](https://www.rwhite.no/plnr/articles/adding_analyses.md),
which builds argsets with `expand_list()`.

Other plan helpers:
[`Plan`](https://www.rwhite.no/plnr/reference/Plan.md),
[`get_anything()`](https://www.rwhite.no/plnr/reference/get_anything.md),
[`is_run_directly()`](https://www.rwhite.no/plnr/reference/is_run_directly.md),
[`set_opts()`](https://www.rwhite.no/plnr/reference/set_opts.md)

## Examples

``` r
argsets <- plnr::expand_list(location = c("oslo", "bergen"), age = c("0-14", "15+"))
str(argsets)
#> List of 4
#>  $ :List of 2
#>   ..$ location: chr "oslo"
#>   ..$ age     : chr "0-14"
#>  $ :List of 2
#>   ..$ location: chr "oslo"
#>   ..$ age     : chr "15+"
#>  $ :List of 2
#>   ..$ location: chr "bergen"
#>   ..$ age     : chr "0-14"
#>  $ :List of 2
#>   ..$ location: chr "bergen"
#>   ..$ age     : chr "15+"
```
