# Create an example R Markdown project structure

This function creates a complete example project structure for an R
Markdown analysis using the `plnr` framework. It sets up a standardized
directory structure and creates example files demonstrating how to use
`plnr` for data analysis and report generation.

## Usage

``` r
create_rmarkdown(home)
```

## Arguments

- home:

  Character string, the path where the project should be created

## Value

NULL, creates files and directories in the specified location

## Details

The created project includes:

- A main `run.R` script that initializes the project and demonstrates
  `plnr` usage

- Example analysis functions in the `R` directory

- A template R Markdown document

- Standard project directories (results, paper, raw)

## See also

[`vignette("plnr")`](https://www.rwhite.no/plnr/articles/plnr.md) for
the framework the generated `run.R` uses: one
[Plan](https://www.rwhite.no/plnr/reference/Plan.md), one `add_data()`
call, and one `add_analysis()` call per output.

## Examples

``` r
# \donttest{
# Create a temporary directory for the example
temp_dir <- tempfile("plnr_example_")
create_rmarkdown(temp_dir)
#> ✔ Setting active project to "/tmp/RtmpnVMcPb/plnr_example_1bf7513ad48c".
#> ✔ Writing a sentinel file .here.
#> ☐ Build robust paths within your project via `here::here()`.
#> ℹ Learn more at <https://here.r-lib.org>.
#> ✔ Setting active project to "<no active project>".

# View the created structure
list.files(temp_dir, recursive = TRUE)
#> [1] "R/figure_death.R" "paper/paper.Rmd"  "run.R"           

unlink(temp_dir, recursive = TRUE)
# }
```
