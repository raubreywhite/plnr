# Create an example R Markdown project structure

`create_rmarkdown()` creates a complete example project structure for an
R Markdown analysis that uses the `plnr` framework. It creates a
standardized directory structure. It also creates example files that
show how to use `plnr` for data analysis and for report generation.

## Usage

``` r
create_rmarkdown(home)
```

## Arguments

- home:

  Character string. The path where `create_rmarkdown()` creates the
  project.

## Value

NULL. `create_rmarkdown()` creates files and directories under `home`.

## Details

The created project includes:

- A main `run.R` script that initializes the project and demonstrates
  `plnr` usage

- Example analysis functions in the `R` directory

- A template R Markdown document

- Standard project directories (results, paper, raw)

## See also

[`vignette("plnr")`](https://www.rwhite.no/plnr/articles/plnr.md) for
the framework the generated `run.R` uses. That `run.R` builds one
[Plan](https://www.rwhite.no/plnr/reference/Plan.md). It then makes one
`add_data()` call, and one `add_analysis()` call per output.

## Examples

``` r
# \donttest{
# Create a temporary directory for the example
temp_dir <- tempfile("plnr_example_")
create_rmarkdown(temp_dir)
#> ✔ Setting active project to "/tmp/RtmpXjBq3V/plnr_example_1bb56a3645d3".
#> ✔ Writing a sentinel file .here.
#> ☐ Build robust paths within your project via `here::here()`.
#> ℹ Learn more at <https://here.r-lib.org>.
#> ✔ Setting active project to "<no active project>".

# View the created structure
list.files(temp_dir, recursive = TRUE)
#> [1] "R/figure_death.R" "R/table_death.R"  "paper/paper.Rmd"  "run.R"           

unlink(temp_dir, recursive = TRUE)
# }
```
