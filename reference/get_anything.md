# Get objects with package namespace support

This function extends [`base::get()`](https://rdrr.io/r/base/get.html)
to support package namespace scoping (e.g., "pkg::var"). It's
particularly useful when working with package exports and
namespace-qualified objects.

## Usage

``` r
get_anything(x)
```

## Arguments

- x:

  Character string specifying the object to retrieve. Can be either a
  simple object name or a namespace-qualified name (e.g., "pkg::var")

## Value

The requested object

## See also

[`vignette("plnr")`](https://www.rwhite.no/plnr/articles/plnr.md), whose
"Function Naming" section covers the `fn_name` strings that a
[Plan](https://www.rwhite.no/plnr/reference/Plan.md) resolves with this
function.

## Examples

``` r
# Get a namespace-qualified object
plnr::get_anything("plnr::nor_covid19_cases_by_time_location")
#>        granularity_time granularity_geo country_iso3 location_code border
#>                  <char>          <char>       <char>        <char>  <int>
#>     1:              day          county          nor  county_nor03   2020
#>     2:              day          county          nor  county_nor03   2020
#>     3:              day          county          nor  county_nor03   2020
#>     4:              day          county          nor  county_nor03   2020
#>     5:              day          county          nor  county_nor03   2020
#>    ---                                                                   
#> 11024:          isoweek          nation          nor    nation_nor   2020
#> 11025:          isoweek          nation          nor    nation_nor   2020
#> 11026:          isoweek          nation          nor    nation_nor   2020
#> 11027:          isoweek          nation          nor    nation_nor   2020
#> 11028:          isoweek          nation          nor    nation_nor   2020
#>           age    sex isoyear isoweek isoyearweek    season seasonweek calyear
#>        <char> <char>   <int>   <int>      <char>    <char>      <num>   <int>
#>     1:  total  total    2020       8     2020-08 2019/2020         31    2020
#>     2:  total  total    2020       8     2020-08 2019/2020         31    2020
#>     3:  total  total    2020       8     2020-08 2019/2020         31    2020
#>     4:  total  total    2020       9     2020-09 2019/2020         32    2020
#>     5:  total  total    2020       9     2020-09 2019/2020         32    2020
#>    ---                                                                       
#> 11024:  total  total    2022      14     2022-14 2021/2022         37      NA
#> 11025:  total  total    2022      15     2022-15 2021/2022         38      NA
#> 11026:  total  total    2022      16     2022-16 2021/2022         39      NA
#> 11027:  total  total    2022      17     2022-17 2021/2022         40      NA
#> 11028:  total  total    2022      18     2022-18 2021/2022         41      NA
#>        calmonth calyearmonth       date covid19_cases_testdate_n
#>           <int>       <char>     <Date>                    <int>
#>     1:        2     2020-M02 2020-02-21                        0
#>     2:        2     2020-M02 2020-02-22                        0
#>     3:        2     2020-M02 2020-02-23                        0
#>     4:        2     2020-M02 2020-02-24                        0
#>     5:        2     2020-M02 2020-02-25                        0
#>    ---                                                          
#> 11024:       NA         <NA> 2022-04-10                     6888
#> 11025:       NA         <NA> 2022-04-17                     3635
#> 11026:       NA         <NA> 2022-04-24                     3764
#> 11027:       NA         <NA> 2022-05-01                     2243
#> 11028:       NA         <NA> 2022-05-08                      502
#>        covid19_cases_testdate_pr100000
#>                                  <num>
#>     1:                        0.000000
#>     2:                        0.000000
#>     3:                        0.000000
#>     4:                        0.000000
#>     5:                        0.000000
#>    ---                                
#> 11024:                      126.961423
#> 11025:                       67.001274
#> 11026:                       69.379036
#> 11027:                       41.343564
#> 11028:                        9.252996

# Get a simple object (same as base::get)
x <- 1
get_anything("x")
#> [1] "x"
```
