# Adding analyses to a plan

This vignette builds three plans on
`nor_covid19_cases_by_time_location`, a dataset of Covid-19 cases in
Norway.
[`vignette("plnr")`](https://www.rwhite.no/plnr/articles/plnr.md)
defines the terms: argset, action function, analysis and plan.

## Single-function plan

A single-function plan applies one action function to many argsets. Add
the argsets first. Then give every argset the same action function with
`apply_action_fn_to_all_argsets()`.

### Many strata

This plan draws one graph for each location.

``` r
library(ggplot2)
library(data.table)
```

    ## 
    ## Attaching package: 'data.table'

    ## The following object is masked from 'package:base':
    ## 
    ##     %notin%

``` r
p <- plnr::Plan$new()

data_fn <- function() {
  return(plnr::nor_covid19_cases_by_time_location)
}
p$add_data(name = "covid19_cases", fn_name = "data_fn")

location_codes <- unique(p$get_data()$covid19_cases$location_code)
location_codes
```

    ##  [1] "county_nor03" "county_nor11" "county_nor15" "county_nor18" "county_nor30"
    ##  [6] "county_nor34" "county_nor38" "county_nor42" "county_nor46" "county_nor50"
    ## [11] "county_nor54" "nation_nor"

``` r
p$add_argset_from_list(
  plnr::expand_list(
    location_code = location_codes,
    granularity_time = "isoweek"
  )
)
p$get_argsets_as_dt()
```

    ##                            name_analysis index_analysis location_code
    ##                                   <char>          <int>        <list>
    ##  1: 42f0e747-02f4-4eda-8ade-ba07fd366d58              1  county_nor03
    ##  2: 7e681add-de9d-4576-95d8-50d3a4737f9a              2  county_nor11
    ##  3: 0e431069-631c-4383-a192-191f81c77184              3  county_nor15
    ##  4: 097bb216-1198-4adb-9936-67f0116ede83              4  county_nor18
    ##  5: ff22e646-6bb2-4ac2-8c9c-48d3d0b973ec              5  county_nor30
    ##  6: 432022e1-de00-4273-95d4-f197395605d7              6  county_nor34
    ##  7: 5c8e19c6-c5cc-4efa-8049-092fb2d6750e              7  county_nor38
    ##  8: 48dde145-2f85-4d30-bcb0-983d1919f8f9              8  county_nor42
    ##  9: de00111b-9be5-438c-ab90-895dcd8dd7a9              9  county_nor46
    ## 10: 1c28fbe0-ab48-49f7-b90f-be30d3e6eb6a             10  county_nor50
    ## 11: c3f1ccff-0822-4198-a717-ee6160c3b95c             11  county_nor54
    ## 12: 47800056-5b99-49ec-8847-de2e0cf16455             12    nation_nor
    ##     granularity_time
    ##               <list>
    ##  1:          isoweek
    ##  2:          isoweek
    ##  3:          isoweek
    ##  4:          isoweek
    ##  5:          isoweek
    ##  6:          isoweek
    ##  7:          isoweek
    ##  8:          isoweek
    ##  9:          isoweek
    ## 10:          isoweek
    ## 11:          isoweek
    ## 12:          isoweek

``` r
action_fn <- function(data, argset) {
  if (plnr::is_run_directly()) {
    data <- p$get_data()
    argset <- p$get_argset(1)
  }
  pd <- data$covid19_cases[
    location_code == argset$location_code &
      granularity_time == argset$granularity_time
  ]

  q <- ggplot(pd, aes(x = date, y = covid19_cases_testdate_n))
  q <- q + geom_line()
  q <- q + labs(title = argset$location_code)
  q
}

p$apply_action_fn_to_all_argsets(fn_name = "action_fn")

q <- p$run_all()
q[[1]]
```

![](adding_analyses_files/figure-html/unnamed-chunk-1-1.png)

``` r
q[[2]]
```

![](adding_analyses_files/figure-html/unnamed-chunk-1-2.png)

### Many variables

This plan crosses two choices: cases or cases per 100 000 population,
and weekly or daily data. It draws one graph for each of the four
combinations.

``` r
p <- plnr::Plan$new()

data_fn <- function() {
  return(plnr::nor_covid19_cases_by_time_location[location_code == "nation_nor"])
}
p$add_data(name = "covid19_cases", fn_name = "data_fn")

p$add_argset_from_list(
  plnr::expand_list(
    variable = c("covid19_cases_testdate_n", "covid19_cases_testdate_pr100000"),
    granularity_time = c("isoweek", "day")
  )
)
p$get_argsets_as_dt()
```

    ##                           name_analysis index_analysis
    ##                                  <char>          <int>
    ## 1: 7a4d8e27-fbb0-41b4-844e-a40a03ce2186              1
    ## 2: 3513d3df-2720-42bb-907d-4f2ea3dd5300              2
    ## 3: 8bbc1452-8a8c-4e3f-ae6e-997abf267a81              3
    ## 4: ba22c8b1-7b03-4a28-8b13-e19aaa321e5c              4
    ##                           variable granularity_time
    ##                             <list>           <list>
    ## 1:        covid19_cases_testdate_n          isoweek
    ## 2:        covid19_cases_testdate_n              day
    ## 3: covid19_cases_testdate_pr100000          isoweek
    ## 4: covid19_cases_testdate_pr100000              day

``` r
action_fn <- function(data, argset) {
  if (plnr::is_run_directly()) {
    data <- p$get_data()
    argset <- p$get_argset(1)
  }
  pd <- data$covid19_cases[granularity_time == argset$granularity_time]

  q <- ggplot(pd, aes(x = date, y = .data[[argset$variable]]))
  q <- q + geom_line()
  q <- q + labs(title = paste(argset$variable, argset$granularity_time))
  q
}

p$apply_action_fn_to_all_argsets(fn_name = "action_fn")

p$run_one(1)
```

![](adding_analyses_files/figure-html/unnamed-chunk-2-1.png)

``` r
p$run_one(2)
```

![](adding_analyses_files/figure-html/unnamed-chunk-2-2.png)

``` r
p$run_one(3)
```

![](adding_analyses_files/figure-html/unnamed-chunk-2-3.png)

``` r
p$run_one(4)
```

![](adding_analyses_files/figure-html/unnamed-chunk-2-4.png)

## Multi-function plan

A multi-function plan gives each analysis its own action function. This
plan makes the figures of a short report. Figure 1 has its own action
function, and figures 2 and 3 share one.

``` r
p <- plnr::Plan$new()

data_fn <- function() {
  return(plnr::nor_covid19_cases_by_time_location)
}
p$add_data(name = "covid19_cases", fn_name = "data_fn")

figure_1 <- function(data, argset) {
  if (plnr::is_run_directly()) {
    data <- p$get_data()
    argset <- p$get_argset("figure_1")
  }
  pd <- data$covid19_cases[granularity_time == "isoweek"]

  q <- ggplot(pd, aes(x = date, y = covid19_cases_testdate_pr100000))
  q <- q + geom_line()
  q <- q + facet_wrap(~location_code)
  q <- q + labs(title = "Weekly Covid-19 cases per 100 000 population")
  q
}

plot_epicurve_by_location <- function(data, argset) {
  if (plnr::is_run_directly()) {
    data <- p$get_data()
    argset <- p$get_argset("figure_2")
  }
  pd <- data$covid19_cases[
    granularity_time == "isoweek" &
      location_code == argset$location_code
  ]

  q <- ggplot(pd, aes(x = date, y = covid19_cases_testdate_n))
  q <- q + geom_line()
  q <- q + labs(title = argset$location_code)
  q
}

p$add_analysis(name = "figure_1", fn_name = "figure_1")
p$add_analysis(
  name = "figure_2",
  fn_name = "plot_epicurve_by_location",
  location_code = "nation_nor"
)
p$add_analysis(
  name = "figure_3",
  fn_name = "plot_epicurve_by_location",
  location_code = "county_nor03"
)

p$run_one("figure_1")
```

![](adding_analyses_files/figure-html/unnamed-chunk-3-1.png)

``` r
p$run_one("figure_2")
```

![](adding_analyses_files/figure-html/unnamed-chunk-3-2.png)

``` r
p$run_one("figure_3")
```

![](adding_analyses_files/figure-html/unnamed-chunk-3-3.png)
