# Get all diagnosis events for patients with specific condition codes Materializes results to a temp table for reliability on large databases

## Usage

``` r
k_get_condition_events(
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

  Character vector of ICD codes (supports

  komodo_schemaSchema containing Komodo tables

  write_schemaSchema where the temp table will be written

  table_nameName for the materialized temp table

  overwriteWhether to drop and recreate if the table already exists
  (default TRUE)

Lazy table pointing at the materialized temp table Get all diagnosis
events for patients with specific condition codes Materializes results
to a temp table for reliability on large databases
