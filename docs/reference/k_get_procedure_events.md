# Get all procedure events for patients with specific procedure codes Materializes results to a temp table for reliability on large databases

## Usage

``` r
k_get_procedure_events(
  con,
  codes,
  komodo_schema = "komodo_ext",
  write_schema,
  table_name,
  overwrite = TRUE
)
```

## Arguments

- con:

  Database connection

- codes:

  Character vector of procedure codes (supports

  komodo_schemaSchema containing Komodo tables

  write_schemaSchema where the temp table will be written

  table_nameName for the materialized temp table

  overwriteWhether to drop and recreate if the table already exists
  (default TRUE)

Lazy table pointing at the materialized temp table Get all procedure
events for patients with specific procedure codes Materializes results
to a temp table for reliability on large databases \# Get all xray
procedures within 5 days of a fracture xray_codes \<- c("71045",
"71046", "73560", "73562") xray_events \<- k_get_procedure_events( con,
codes = xray_codes, write_schema = write_schema, table_name =
"xray_events" )cohort \<- k_get_condition_events( con, codes = c("S72%",
"S82%"), write_schema = write_schema, table_name = "fracture_events" )
\|\> inner_join(xray_events, by = "patient_id") \|\> filter(
procedure_date \>= diagnosis_date, procedure_date \<= diagnosis_date +
lubridate::days(5) ) \|\> distinct(patient_id)
