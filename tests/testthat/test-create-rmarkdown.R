test_that("create_rmarkdown() writes every R file that run.R calls", {
  home <- fs::path(tempfile("plnr-create-rmarkdown-"))
  on.exit(unlink(home, recursive = TRUE, force = TRUE), add = TRUE)

  create_rmarkdown(home)

  # run.R dispatches on fn_name, so every fn_name it names must have a file
  # that defines it. table_death was written to figure_death.R and then
  # overwritten, so the generated project could not run.
  expect_true(fs::file_exists(fs::path(home, "R", "table_death.R")))
  expect_true(fs::file_exists(fs::path(home, "R", "figure_death.R")))

  expect_match(
    paste(readLines(fs::path(home, "R", "table_death.R")), collapse = "\n"),
    "table_death <- function"
  )
  expect_match(
    paste(readLines(fs::path(home, "R", "figure_death.R")), collapse = "\n"),
    "figure_death <- function"
  )

  run <- paste(readLines(fs::path(home, "run.R")), collapse = "\n")
  defined <- unlist(lapply(
    fs::dir_ls(fs::path(home, "R"), glob = "*.R"),
    function(f) {
      x <- paste(readLines(f), collapse = "\n")
      regmatches(x, gregexpr("[a-zA-Z0-9_.]+(?= <- function)", x, perl = TRUE))[[1]]
    }
  ))
  called <- regmatches(
    run,
    gregexpr('(?<=fn_name = ")[a-zA-Z0-9_.]+(?=")', run, perl = TRUE)
  )[[1]]
  expect_true(all(called %in% defined))
})
