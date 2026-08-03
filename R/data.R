#' Covid-19 data for PCR-confirmed cases in Norway (nation and county)
#'
#' This data comes from the Norwegian Surveillance System for Communicable Diseases (MSIS).
#' The date corresponds to when the PCR-test was taken.
#'
#' The raw number of cases and cases per 100.000 population are recorded.
#'
#' This data was extracted on 2022-05-04.
#'
#' @format A csfmt_rts_data_v1 with 11028 rows and 18 variables:
#' \describe{
#'   \item{granularity_time}{day/isoweek}
#'   \item{granularity_geo}{nation, county}
#'   \item{country_iso3}{nor}
#'   \item{location_code}{norge, 11 counties}
#'   \item{border}{2020}
#'   \item{age}{total}
#'   \item{isoyear}{Isoyear of event}
#'   \item{isoweek}{Isoweek of event}
#'   \item{isoyearweek}{Isoyearweek of event}
#'   \item{season}{Season of event}
#'   \item{seasonweek}{Seasonweek of event}
#'   \item{calyear}{Calyear of event}
#'   \item{calmonth}{Calmonth of event}
#'   \item{calyearmonth}{Calyearmonth of event}
#'   \item{date}{Date of event}
#'   \item{covid19_cases_testdate_n}{Number of confirmed covid19 cases}
#'   \item{covid19_cases_testdate_pr100000}{Number of confirmed covid19 cases per 100.000 population}
#' }
#' @source \url{https://github.com/folkehelseinstituttet/surveillance_data/blob/master/covid19/_DOCUMENTATION_data_covid19_msis_by_time_location.txt}
"nor_covid19_cases_by_time_location"


#' An example data_fn that returns a data set
#' @examples
#' # A data function takes no arguments and returns one data set
#' d <- example_data_fn_nor_covid19_cases_by_time_location()
#' dim(d)
#'
#' # Its intended use is as an `fn_name` passed to Plan$add_data()
#' p <- plnr::Plan$new()
#' p$add_data(
#'   name = "covid19_cases",
#'   fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location"
#' )
#' names(p$get_data())
#' @family example and test functions
#' @seealso `vignette("adding_analyses")`, which defines the same kind of
#' zero-argument `data_fn` and attaches it to a plan with `fn_name`.
#' @export
example_data_fn_nor_covid19_cases_by_time_location <- function() {
  plnr::nor_covid19_cases_by_time_location
}
