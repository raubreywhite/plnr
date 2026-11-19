# The synthetic registries of the plnr case study. Each article sources this
# file; vignettes/articles/case-study-contract.Rmd prints and explains it.

## ---- raw ----
library(data.table)

calendar <- cstime::dates_by_isoyearweek[, .(
  isoyearweek,
  isoweek = cstime::isoyearweek_to_isoweek_n(isoyearweek),
  monday = as.Date(mon)
)]
calendar <- calendar[isoyearweek >= "2018-35" & isoyearweek <= "2024-03"]
today <- max(calendar$monday) + 6L
districts <- c("district_a", "district_b", "district_c")
season <- function(isoweek, peak) cos(2 * pi * (isoweek - peak) / 52)

set.seed(4)

# General practice: one file a week, one row for each district and week, one
# column for each diagnosis group.
raw_gp <- CJ(district = districts, isoyearweek = calendar$isoyearweek)
raw_gp[calendar, on = "isoyearweek", isoweek := i.isoweek]
raw_gp[, all_n := rpois(.N, 2000)]
raw_gp[, ili_n := rbinom(.N, all_n, plogis(-4 + 1.2 * season(isoweek, 5)))]
raw_gp[, isoweek := NULL]

# Hospitals: one row for each admission, with the date it reached the registry.
raw_hosp <- calendar[,
  .(
    admission_date = monday +
      sample(0:6, rpois(1, 20 * exp(1.1 * season(isoweek, 6))), TRUE)
  ),
  by = .(isoyearweek, isoweek)
]
raw_hosp[, district := sample(districts, .N, TRUE)]
raw_hosp[,
  diagnosis := sample(c("SARI", "other"), .N, TRUE, prob = c(0.8, 0.2))
]
raw_hosp[, registered_date := admission_date + rgeom(.N, 0.25)]
raw_hosp <- raw_hosp[
  registered_date <= today,
  .(admission_date, registered_date, district, diagnosis)
]

# The laboratory: one row for each test, with the results for two pathogens and
# the date the result was reported. National only.
raw_lab <- calendar[,
  .(
    sample_date = monday +
      sample(0:6, rpois(1, 400 + 120 * season(isoweek, 3)), TRUE)
  ),
  by = .(isoyearweek, isoweek)
]
raw_lab[, influenza := rbinom(.N, 1, plogis(-2.6 + 1.6 * season(isoweek, 5)))]
raw_lab[, rsv := rbinom(.N, 1, plogis(-3.0 + 1.4 * season(isoweek, 50)))]
raw_lab[,
  reported_date := sample_date + sample(0:20, .N, TRUE, prob = 0.8^(0:20))
]
raw_lab <- raw_lab[
  reported_date <= today,
  .(sample_date, reported_date, influenza, rsv)
]

## ---- get_data ----
monday_of <- function(isoyearweek) {
  weeks <- cstime::dates_by_isoyearweek
  as.Date(weeks$mon[match(isoyearweek, weeks$isoyearweek)])
}
week_of <- function(date) cstime::date_to_isoyearweek_c(date)
add_national <- function(d) {
  national <- d[,
    .(
      location_code = "national",
      numerator = sum(numerator),
      denominator = sum(denominator)
    ),
    keyby = .(indicator_tag, age, sex, isoyearweek_reference, reporting_date)
  ]
  rbindlist(list(d, national), use.names = TRUE)
}

get_data_gp <- function(raw = raw_gp) {
  # no reporting date: each week is complete when it arrives, so it counts as
  # reported on the Monday of its reference week (rule 6)
  d <- raw[, .(
    indicator_tag = "gp_ili",
    location_code = district,
    age = "total",
    sex = "total",
    isoyearweek_reference = isoyearweek,
    reporting_date = monday_of(isoyearweek),
    numerator = ili_n,
    denominator = all_n
  )]
  add_national(d)
}

get_data_hosp <- function(raw = raw_hosp) {
  d <- raw[
    diagnosis == "SARI",
    .(numerator = .N),
    keyby = .(
      location_code = district,
      isoyearweek_reference = week_of(admission_date),
      reporting_date = registered_date
    )
  ]
  d[, `:=`(
    indicator_tag = "hosp_sari",
    age = "total",
    sex = "total",
    denominator = NA_integer_
  )]
  add_national(d)
}

get_data_lab <- function(raw = raw_lab) {
  d <- melt(
    raw,
    id.vars = c("sample_date", "reported_date"),
    variable.name = "pathogen",
    value.name = "positive"
  )
  d <- d[,
    .(numerator = sum(positive), denominator = .N),
    keyby = .(
      indicator_tag = paste0("lab_", pathogen),
      isoyearweek_reference = week_of(sample_date),
      reporting_date = reported_date
    )
  ]
  d[, `:=`(location_code = "national", age = "total", sex = "total")]
  setcolorder(d, contract_cols)
}

## ---- check_contract ----
contract_cols <- c(
  "indicator_tag",
  "location_code",
  "age",
  "sex",
  "isoyearweek_reference",
  "reporting_date",
  "numerator",
  "denominator"
)
contract_key <- setdiff(contract_cols, c("numerator", "denominator"))

check_contract <- function(d, registry) {
  if (!is.data.table(d)) {
    stop("registry ", registry, " breaks rule 1: not a data.table", call. = FALSE)
  }
  missing <- setdiff(contract_cols, names(d))
  if (length(missing) > 0) {
    stop(
      "registry ",
      registry,
      " breaks rule 1: no column ",
      paste(missing, collapse = ", "),
      call. = FALSE
    )
  }
  broken <- c(
    "2: a key column is not character" = !all(sapply(
      d[, setdiff(contract_key, "reporting_date"), with = FALSE],
      is.character
    )),
    "2: reporting_date is not a Date" = !inherits(d$reporting_date, "Date"),
    "3: a key value or a numerator is missing" = anyNA(d[,
      c(contract_key, "numerator"),
      with = FALSE
    ]),
    "4: isoyearweek_reference is not an ISO week YYYY-WW" = anyNA(monday_of(
      d$isoyearweek_reference
    )),
    "5: two rows share a key" = anyDuplicated(d, by = contract_key) > 0,
    "6: a count is reported before its reference week" = any(
      d$reporting_date < monday_of(d$isoyearweek_reference),
      na.rm = TRUE
    ),
    "7: a count is negative, infinite or not whole" = any(
      d$numerator < 0 | is.infinite(d$numerator) | d$numerator %% 1 != 0,
      d$denominator < 0 | is.infinite(d$denominator),
      na.rm = TRUE
    ),
    "8: a numerator is above its denominator" = any(
      d$numerator > d$denominator,
      na.rm = TRUE
    ),
    "9: no location_code national" = !"national" %in% d$location_code
  )
  if (any(broken)) {
    stop(
      "registry ",
      registry,
      " breaks rule ",
      paste(names(broken)[broken], collapse = "; rule "),
      call. = FALSE
    )
  }
  invisible(d)
}
