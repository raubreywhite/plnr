# Covid-19 data for PCR-confirmed cases in Norway (nation and county)

The Norwegian Surveillance System for Communicable Diseases (MSIS)
supplies this data. The date corresponds to when the PCR-test was taken.

## Usage

``` r
nor_covid19_cases_by_time_location
```

## Format

A csfmt_rts_data_v1 with 11028 rows and 18 variables:

- granularity_time:

  day/isoweek

- granularity_geo:

  nation, county

- country_iso3:

  nor

- location_code:

  norge, 11 counties

- border:

  2020

- age:

  total

- isoyear:

  Isoyear of event

- isoweek:

  Isoweek of event

- isoyearweek:

  Isoyearweek of event

- season:

  Season of event

- seasonweek:

  Seasonweek of event

- calyear:

  Calyear of event

- calmonth:

  Calmonth of event

- calyearmonth:

  Calyearmonth of event

- date:

  Date of event

- covid19_cases_testdate_n:

  Number of confirmed covid19 cases

- covid19_cases_testdate_pr100000:

  Number of confirmed covid19 cases per 100.000 population

## Source

<https://github.com/folkehelseinstituttet/surveillance_data/blob/master/covid19/_DOCUMENTATION_data_covid19_msis_by_time_location.txt>

## Details

The data records the raw number of cases, and the number of cases per
100.000 population.

The extraction date of this data is 2022-05-04.
