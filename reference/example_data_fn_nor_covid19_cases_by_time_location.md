# Return the example Covid-19 dataset

`example_data_fn_nor_covid19_cases_by_time_location()` is an example
data function: it takes no arguments and returns one dataset. Give its
name to `Plan$add_data()` as `fn_name`.

## Usage

``` r
example_data_fn_nor_covid19_cases_by_time_location()
```

## Value

[nor_covid19_cases_by_time_location](https://www.rwhite.no/plnr/reference/nor_covid19_cases_by_time_location.md),
a data.table.

## See also

[`vignette("adding_analyses")`](https://www.rwhite.no/plnr/articles/adding_analyses.md),
which writes its own data functions.

Other example and test functions:
[`example_action_fn()`](https://www.rwhite.no/plnr/reference/example_action_fn.md),
[`test_action_fn()`](https://www.rwhite.no/plnr/reference/test_action_fn.md)

## Examples

``` r
dim(example_data_fn_nor_covid19_cases_by_time_location())
#> [1] 11028    18

p <- plnr::Plan$new()
p$add_data(
  name = "covid19_cases",
  fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location"
)
names(p$get_data())
#> [1] "covid19_cases" "hash"         
```
