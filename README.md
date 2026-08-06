# plnr <a href="https://www.rwhite.no/plnr/"><img src="man/figures/logo.png" align="right" width="120" /></a>

[![CRAN status](https://www.r-pkg.org/badges/version/plnr)](https://cran.r-project.org/package=plnr)
[![CRAN downloads](https://cranlogs.r-pkg.org/badges/plnr)](https://cran.r-project.org/package=plnr)

## Overview

[plnr](https://www.rwhite.no/plnr/) is a framework for planning and executing analyses in R. Use it when you need to do one of these:

- Run the same function multiple times with different arguments
- Run multiple different functions on the same datasets
- Create systematic analyses across multiple strata or variables

### Key Features

- **Efficient Data Management**: Load the data once and reuse it across multiple analyses
- **Structured Analysis Planning**: Organize analyses into clear, maintainable plans
- **Flexible Execution**: Support for both single-function and multi-function analysis plans
- **Built-in Debugging**: Tools for development and testing
- **Parallel Processing**: Optional parallel execution of analyses
- **Hash-based Caching**: Track data changes and optimize execution

### Common Use Cases

- Apply the same analysis across multiple strata, such as locations or age groups
- Run statistical methods on multiple variables, such as exposures or outcomes
- Create multiple tables or graphs for reports
- Create systematic surveillance analyses

## Installation from CRAN

```r
install.packages("plnr")
```

## Getting Started

1. Read the [introduction vignette](https://www.rwhite.no/plnr/articles/plnr.html).
2. Read the [adding analyses guide](https://www.rwhite.no/plnr/articles/adding_analyses.html).
3. Run `help(package="plnr")` for the function documentation.

## Quick Example

```r
library(plnr)
library(ggplot2)
library(data.table)

# Create a new plan
p <- Plan$new()

# Add data
p$add_data(
  name = "deaths",
  direct = data.table(deaths=1:4, year=2001:2004)
)

# Add analyses for different years
p$add_argset(name = "fig_1_2002", year_max = 2002)
p$add_argset(name = "fig_1_2003", year_max = 2003)

# Define analysis function
fn_fig_1 <- function(data, argset) {
  plot_data <- data$deaths[year <= argset$year_max]
  ggplot(plot_data, aes(x=year, y=deaths)) +
    geom_line() +
    geom_point(size=3) +
    labs(title = glue::glue("Deaths from 2001 until {argset$year_max}"))
}

# Apply function to all argsets
p$apply_action_fn_to_all_argsets(fn_name = "fn_fig_1")

# Run analyses
p$run_one("fig_1_2002")
```

## Contributing

Contributions are welcome. Submit a [Pull Request](https://github.com/raubreywhite/plnr/pulls).

## License

The MIT License covers this package. Read the [LICENSE](LICENSE) file for the full text.
