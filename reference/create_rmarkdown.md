# Create an example R Markdown project that uses plnr

`create_rmarkdown()` writes a small project to `home`. Its `run.R`
builds a [Plan](https://www.rwhite.no/plnr/reference/Plan.md) with one
dataset and two analyses, then renders a report that runs them.

## Usage

``` r
create_rmarkdown(home)
```

## Arguments

- home:

  Character string. The directory for the project.

## Value

The project path, invisibly, as
[`usethis::create_project()`](https://usethis.r-lib.org/reference/create_package.html)
returns it.

## Details

The project holds:

- `run.R`, which calls `org::initialize_project()`, builds the plan and
  renders the report.

- `R/table_death.R` and `R/figure_death.R`, the two action functions.

- `paper/paper.Rmd`, the report.

- The empty directories `results` and `raw`.

`run.R` needs the org, ggplot2, huxtable, lubridate and rmarkdown
packages. plnr does not install them.

## See also

[`vignette("plnr")`](https://www.rwhite.no/plnr/articles/plnr.md) for
the concepts that `run.R` uses.

Other utilities:
[`try_again()`](https://www.rwhite.no/plnr/reference/try_again.md)

## Examples

``` r
# \donttest{
home <- tempfile("plnr_example_")
create_rmarkdown(home)
#> ✔ Setting active project to "/tmp/RtmpeX3tAJ/plnr_example_1bc02ef71e87".
#> ✔ Writing a sentinel file .here.
#> ☐ Build robust paths within your project via `here::here()`.
#> ℹ Learn more at <https://here.r-lib.org>.
#> ✔ Setting active project to "<no active project>".
list.files(home, recursive = TRUE)
#> [1] "R/figure_death.R" "R/table_death.R"  "paper/paper.Rmd"  "run.R"           
unlink(home, recursive = TRUE)
# }
```
