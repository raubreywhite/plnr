# Find an object by name

`get_anything()` returns the object that a name refers to.
[Plan](https://www.rwhite.no/plnr/reference/Plan.md) uses it to find the
function that `fn_name` names.

## Usage

``` r
get_anything(x, envir = parent.frame(), mode = "any")
```

## Arguments

- x:

  Character string. The name of the object.

- envir:

  The environment where step 2 starts. The default is the environment
  that calls `get_anything()`.

- mode:

  The type of object to find, as in
  [`base::get()`](https://rdrr.io/r/base/get.html).
  [Plan](https://www.rwhite.no/plnr/reference/Plan.md) uses
  `"function"`.

## Value

The object that `x` names. `get_anything()` stops with an error when no
object matches.

## Details

`get_anything()` looks in this order and returns the first match:

1.  For `"pkg::name"`, the object that package `pkg` exports. It looks
    nowhere else.

2.  The environments from `envir` up to, but not including, the first
    global environment or package namespace above it.

3.  The global environment, then the search path.

4.  The plnr namespace, then the packages that plnr imports.

## See also

[`vignette("plnr")`](https://www.rwhite.no/plnr/articles/plnr.md), whose
"Function names" section shows how a
[Plan](https://www.rwhite.no/plnr/reference/Plan.md) uses `fn_name`.

Other plan helpers:
[`Plan`](https://www.rwhite.no/plnr/reference/Plan.md),
[`expand_list()`](https://www.rwhite.no/plnr/reference/expand_list.md),
[`is_run_directly()`](https://www.rwhite.no/plnr/reference/is_run_directly.md),
[`set_opts()`](https://www.rwhite.no/plnr/reference/set_opts.md)

## Examples

``` r
# Get a namespace-qualified object
head(plnr::get_anything("plnr::nor_covid19_cases_by_time_location"))
#>    granularity_time granularity_geo country_iso3 location_code border    age
#>              <char>          <char>       <char>        <char>  <int> <char>
#> 1:              day          county          nor  county_nor03   2020  total
#> 2:              day          county          nor  county_nor03   2020  total
#> 3:              day          county          nor  county_nor03   2020  total
#> 4:              day          county          nor  county_nor03   2020  total
#> 5:              day          county          nor  county_nor03   2020  total
#> 6:              day          county          nor  county_nor03   2020  total
#>       sex isoyear isoweek isoyearweek    season seasonweek calyear calmonth
#>    <char>   <int>   <int>      <char>    <char>      <num>   <int>    <int>
#> 1:  total    2020       8     2020-08 2019/2020         31    2020        2
#> 2:  total    2020       8     2020-08 2019/2020         31    2020        2
#> 3:  total    2020       8     2020-08 2019/2020         31    2020        2
#> 4:  total    2020       9     2020-09 2019/2020         32    2020        2
#> 5:  total    2020       9     2020-09 2019/2020         32    2020        2
#> 6:  total    2020       9     2020-09 2019/2020         32    2020        2
#>    calyearmonth       date covid19_cases_testdate_n
#>          <char>     <Date>                    <int>
#> 1:     2020-M02 2020-02-21                        0
#> 2:     2020-M02 2020-02-22                        0
#> 3:     2020-M02 2020-02-23                        0
#> 4:     2020-M02 2020-02-24                        0
#> 5:     2020-M02 2020-02-25                        0
#> 6:     2020-M02 2020-02-26                        2
#>    covid19_cases_testdate_pr100000
#>                              <num>
#> 1:                       0.0000000
#> 2:                       0.0000000
#> 3:                       0.0000000
#> 4:                       0.0000000
#> 5:                       0.0000000
#> 6:                       0.2883947

# Get an object from the calling environment
f <- function() {
  x <- 1
  get_anything("x")
}
f()
#> [1] 1
```
