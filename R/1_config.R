set_config <- function() {
  # if (!foreach::getDoParRegistered()) foreach::registerDoSEQ()
  config$force_verbose <- FALSE
  return(invisible(config$force_verbose))
}
