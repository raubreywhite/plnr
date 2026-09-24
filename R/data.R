#' Covid-19 cases confirmed by PCR in Norway, by nation and county
#'
#' The data come from the Norwegian Surveillance System for Communicable
#' Diseases (MSIS). `date` is the date of the PCR test. The data were extracted
#' on 2022-05-04.
#'
#' @format A data.table with 11028 rows and 18 variables:
#' \describe{
#'   \item{granularity_time}{`"day"` or `"isoweek"`.}
#'   \item{granularity_geo}{`"nation"` or `"county"`.}
#'   \item{country_iso3}{`"nor"`.}
#'   \item{location_code}{`"nation_nor"`, or one of 11 county codes such as `"county_nor03"`.}
#'   \item{border}{The year of the county borders, 2020.}
#'   \item{age}{`"total"`.}
#'   \item{sex}{`"total"`.}
#'   \item{isoyear}{ISO year.}
#'   \item{isoweek}{ISO week.}
#'   \item{isoyearweek}{ISO year and week, such as `"2020-08"`.}
#'   \item{season}{Season, such as `"2020/2021"`.}
#'   \item{seasonweek}{Week within the season.}
#'   \item{calyear}{Calendar year. `NA` in weekly rows.}
#'   \item{calmonth}{Calendar month. `NA` in weekly rows.}
#'   \item{calyearmonth}{Calendar year and month, such as `"2020-M02"`. `NA` in weekly rows.}
#'   \item{date}{The date. In weekly rows, the Sunday that ends the ISO week.}
#'   \item{covid19_cases_testdate_n}{Number of confirmed cases.}
#'   \item{covid19_cases_testdate_pr100000}{Number of confirmed cases per 100 000 population.}
#' }
#' @source \url{https://github.com/folkehelseinstituttet/surveillance_data/blob/master/covid19/_DOCUMENTATION_data_covid19_msis_by_time_location.txt}
"nor_covid19_cases_by_time_location"


#' Return the example Covid-19 dataset
#'
#' `example_data_fn_nor_covid19_cases_by_time_location()` is an example data
#' function: it takes no arguments and returns one dataset. Give its name to
#' `Plan$add_data()` as `fn_name`.
#'
#' @return [nor_covid19_cases_by_time_location], a data.table.
#' @examples
#' dim(example_data_fn_nor_covid19_cases_by_time_location())
#'
#' p <- plnr::Plan$new()
#' p$add_data(
#'   name = "covid19_cases",
#'   fn_name = "plnr::example_data_fn_nor_covid19_cases_by_time_location"
#' )
#' names(p$get_data())
#' @family example and test functions
#' @seealso `vignette("adding_analyses")`, which writes its own data functions.
#' @export
example_data_fn_nor_covid19_cases_by_time_location <- function() {
  return(plnr::nor_covid19_cases_by_time_location)
}
