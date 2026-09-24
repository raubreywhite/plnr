# plnr <a href="https://www.rwhite.no/plnr/"><img src="man/figures/logo.png" align="right" width="120" /></a>

[![CRAN status](https://www.r-pkg.org/badges/version/plnr)](https://cran.r-project.org/package=plnr)
[![CRAN downloads](https://cranlogs.r-pkg.org/badges/plnr)](https://cran.r-project.org/package=plnr)

[plnr](https://www.rwhite.no/plnr/) runs many analyses on the same data. You add the data and the analyses to a plan, and the plan runs them. Use it to apply one method across strata such as locations or age groups, or across exposures and outcomes. Use it also to make the tables and figures of a report.

## Installation

```r
install.packages("plnr")
```

## Quick start

```r
library(plnr)

# An action function takes the data and one argset
total_deaths <- function(data, argset) {
  d <- data$deaths
  return(sum(d$deaths[d$year <= argset$year_max]))
}

p <- Plan$new()
p$add_data(
  name = "deaths",
  direct = data.frame(year = 2001:2004, deaths = c(10, 12, 9, 15))
)
p$add_argset(name = "to_2002", year_max = 2002)
p$add_argset(name = "to_2004", year_max = 2004)
p$apply_action_fn_to_all_argsets(fn_name = "total_deaths")

p$run_one("to_2002")
#> [1] 22

results <- p$run_all()
unlist(results)
#> [1] 22 46
```

## Which function do I want?

| To | Use |
|---|---|
| Start a plan | `Plan$new()` |
| Add a dataset | `p$add_data()` |
| Add argsets | `p$add_argset()`, `p$add_argset_from_list()`, `p$add_argset_from_df()` |
| Make argsets from every combination of values | `expand_list()` |
| Give every argset the same action function | `p$apply_action_fn_to_all_argsets()` |
| Add analyses that have their own action function | `p$add_analysis()`, `p$add_analysis_from_list()`, `p$add_analysis_from_df()` |
| Run analyses | `p$run_one()`, `p$run_all()` |
| Develop an action function | `p$get_data()`, `p$get_argset()`, `is_run_directly()` |

## Learn more

- [Introduction](https://www.rwhite.no/plnr/articles/plnr.html): the concepts, and how plnr finds a function by name.
- [Adding analyses](https://www.rwhite.no/plnr/articles/adding_analyses.html): single-function and multi-function plans on real data.
- [Reference](https://www.rwhite.no/plnr/reference/index.html): every function.
