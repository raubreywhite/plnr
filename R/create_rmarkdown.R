#' Create an example R Markdown project that uses plnr
#'
#' `create_rmarkdown()` writes a small project to `home`. Its `run.R` builds a
#' [Plan] with one dataset and two analyses, then renders a report that runs
#' them.
#'
#' The project holds:
#' - `run.R`, which calls `org::initialize_project()`, builds the plan and
#'   renders the report.
#' - `R/table_death.R` and `R/figure_death.R`, the two action functions.
#' - `paper/paper.Rmd`, the report.
#' - The empty directories `results` and `raw`.
#'
#' `run.R` needs the org, ggplot2, huxtable, lubridate and rmarkdown packages.
#' plnr does not install them.
#'
#' @param home Character string. The directory for the project.
#' @return The project path, invisibly, as `usethis::create_project()` returns
#' it.
#' @examples
#' \donttest{
#' home <- tempfile("plnr_example_")
#' create_rmarkdown(home)
#' list.files(home, recursive = TRUE)
#' unlink(home, recursive = TRUE)
#' }
#' @family utilities
#' @seealso `vignette("plnr")` for the concepts that `run.R` uses.
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

  writeLines(txt, fs::path(home, "run.R"))

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

  writeLines(txt, fs::path(home, "R", "table_death.R"))

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

  writeLines(txt, fs::path(home, "R", "figure_death.R"))

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

  writeLines(txt, fs::path(home, "paper", "paper.Rmd"))

  return(usethis::create_project(home))
}
