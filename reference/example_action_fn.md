# Print what an action function receives

`example_action_fn()` is an example action function. It prints the names
of the datasets in `data` and the names of the elements in `argset`.

## Usage

``` r
example_action_fn(data, argset)
```

## Arguments

- data:

  A named list of datasets, as a
  [Plan](https://www.rwhite.no/plnr/reference/Plan.md) passes it.

- argset:

  A named list of arguments for one analysis.

## Value

`names(argset)`, invisibly.

## See also

[`vignette("plnr")`](https://www.rwhite.no/plnr/articles/plnr.md) for
what an action function is.

Other example and test functions:
[`example_data_fn_nor_covid19_cases_by_time_location()`](https://www.rwhite.no/plnr/reference/example_data_fn_nor_covid19_cases_by_time_location.md),
[`test_action_fn()`](https://www.rwhite.no/plnr/reference/test_action_fn.md)

## Examples

``` r
p <- plnr::Plan$new()
p$add_data("covid_data", fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location")
p$add_analysis_from_list(
  fn_name = "plnr::example_action_fn",
  l = list(
    list(name = "analysis_1", var_1 = 1),
    list(name = "analysis_2", var_1 = 2)
  )
)
p$run_one("analysis_1")
#> [1] "Data given:"
#> [1] "covid_data" "hash"      
#> [1] "Argset given:"
#> [1] "var_1"          "index_analysis"
#> [1] "var_1"          "index_analysis"
```
