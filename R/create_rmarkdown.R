#' Create an example R Markdown project structure
#'
#' `create_rmarkdown()` creates a complete example project structure for an R
#' Markdown analysis that uses the `plnr` framework. It creates a standardized
#' directory structure. It also creates example files that show how to use
#' `plnr` for data analysis and for report generation.
#'
#' The created project includes:
#' - A main `run.R` script that initializes the project and demonstrates `plnr` usage
#' - Example analysis functions in the `R` directory
#' - A template R Markdown document
#' - Standard project directories (results, paper, raw)
#'
#' @param home Character string. The path where `create_rmarkdown()` creates the
#' project.
#' @return NULL. `create_rmarkdown()` creates files and directories under
#' `home`.
#' @examples
#' \donttest{
#' # Create a temporary directory for the example
#' temp_dir <- tempfile("plnr_example_")
#' create_rmarkdown(temp_dir)
#'
#' # View the created structure
#' list.files(temp_dir, recursive = TRUE)
#'
#' unlink(temp_dir, recursive = TRUE)
#' }
#' @seealso `vignette("plnr")` for the framework the generated `run.R` uses. That
#' `run.R` builds one [Plan]. It then makes one `add_data()` call, and one
#' `add_analysis()` call per output.
#' @export
create_rmarkdown <- function(home) {
  fs::dir_create(fs::path(home))
  fs::dir_create(fs::path(home, "R"))
  fs::dir_create(fs::path(home, "results"))
  fs::dir_create(fs::path(home, "paper"))
  fs::dir_create(fs::path(home, "raw"))

  # delete some files if not needed
  unlink(fs::dir_ls(home, regexp = "*Rproj$"))

  ############
  # run.R

  txt <- glue::glue(
    '
# Initialize the project
org::initialize_project(
  home = "{home}",
  results = "{fs::path(home,"results")}",
  paper = "{fs::path(home,"paper")}",
  raw = "{fs::path(home,"raw")}",
  create_folders = TRUE
)

library(ggplot2)
library(data.table)

# info.txt
txt <- glue::glue("
{{lubridate::today()}}:
  Project initialized.
", .trim=FALSE)

org::write_text(
  txt = txt,
  file = fs::path(org::project$results, "info.txt")
)

# define a new plan
p <- plnr::Plan$new()

# adding data
p$add_data(
  name = "deaths",
  direct = data.table(deaths=1:4, year=2001:2004)
)

# adding analyses
p$add_analysis(
  name = "tab_1",
  fn_name = "table_death"
)

p$add_analysis(
  name = "fig_1",
  fn_name = "figure_death",
  year_max = 2004
)

# render the paper
rmarkdown::render(
  input = fs::path(org::project$paper,"paper.Rmd"),
  output_dir = org::project$results_today,
  quiet = F
)
',
    home = home
  )

  cat(txt, file = fs::path(home, "run.R"))

  ############
  # R/table_death.R

  txt <- glue::glue(
    '
table_death <- function(data, argset){{
  # data <- p$get_data()
  # argset <- p$get_argset("tab_1")

  ht <- huxtable::hux(data$deaths, add_colnames = TRUE)
  ht <- huxtable::theme_article(ht)
  ht
}}
'
  )

  cat(txt, file = fs::path(home, "R", "figure_death.R"))

  ############
  # R/figure_death.R

  txt <- glue::glue(
    '
figure_death <- function(data, argset){{
  # data <- p$get_data()
  # argset <- p$get_argset("fig_1")

  plot_data <- data$deaths[year<= argset$year_max]

  q <- ggplot(plot_data, aes(x=year, y=deaths))
  q <- q + geom_line()
  q <- q + geom_point(size=3)
  q <- q + labs(title = glue::glue("Deaths from 2001 until {{argset$year_max}}"))
  q
}}
'
  )

  cat(txt, file = fs::path(home, "R", "figure_death.R"))

  ############
  # paper/paper.Rmd

  txt <- glue::glue(
    '
---
title: "Untitled"
output: html_document
editor_options:
  chunk_output_type: console
---

```{{r setup, include=FALSE}}
knitr::opts_chunk$set(echo = TRUE)
```

## Table

Here is a table:

```{{r, echo=FALSE, results="asis"}}
p$run_one("tab_1")
```

## Plot

Here is a plot:

```{{r, echo=FALSE}}
p$run_one("fig_1")
```

  '
  )

  cat(txt, file = fs::path(home, "paper", "paper.Rmd"))

  usethis::create_project(home)
}
