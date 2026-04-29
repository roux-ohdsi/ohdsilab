# Get all procedure events for patients with specific procedure codes Returns every occurrence, not just the first, enabling timing-based cohort logic

## Usage

``` r
k_get_procedure_events(connection, codes, komodo_schema = "komodo_ext")
```

## Arguments

- connection:

  Database connection

- codes:

  Character vector of procedure codes (supports

  komodo_schemaSchema containing Komodo tables

Lazy table with patient_id and procedure_date Get all procedure events
for patients with specific procedure codes Returns every occurrence, not
just the first, enabling timing-based cohort logic \# Get all xray
procedures within 5 days of a fracture xray_codes \<- c("71045",
"71046", "73560", "73562") xray_events \<- k_get_procedure_events(con,
codes = xray_codes)cohort \<- k_get_condition_events(con, codes =
c("S72.%", "S82.%")) \|\> inner_join(xray_events, by = "patient_id")
\|\> filter( procedure_date \>= diagnosis_date, procedure_date \<=
diagnosis_date + lubridate::days(5) ) \|\> distinct(patient_id)
