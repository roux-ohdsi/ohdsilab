# Get all diagnosis events for patients with specific condition codes Returns every occurrence, not just the first, enabling timing-based cohort logic

## Usage

``` r
k_get_condition_events(connection, codes, komodo_schema = "komodo_ext")
```

## Arguments

- connection:

  Database connection

- codes:

  Character vector of ICD codes (supports

  komodo_schemaSchema containing Komodo tables

Lazy table with patient_id and diagnosis_date Get all diagnosis events
for patients with specific condition codes Returns every occurrence, not
just the first, enabling timing-based cohort logic \# Get all fracture
events, then filter relative to a prescription fracture_events \<-
k_get_condition_events( con, codes = c("S72.%", "S82.%") )cohort \<-
fracture_events \|\> inner_join( pharmacy \|\> filter(generic_name ==
"lisinopril") \|\> select(patient_id, prescription_date = service_date),
by = "patient_id" ) \|\> filter( diagnosis_date \>= prescription_date,
diagnosis_date \<= prescription_date + lubridate::days(5) ) \|\>
distinct(patient_id)# Washout: no fracture in 365 days before
prescription clean_cohort \<- lisinopril_patients \|\> anti_join(
fracture_events \|\> inner_join(lisinopril_patients, by = "patient_id")
\|\> filter( diagnosis_date \>= prescription_date - 365, diagnosis_date
\< prescription_date ), by = "patient_id" )
