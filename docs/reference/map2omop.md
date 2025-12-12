# map2omop

translates any codes to omop concept ID as long as there is a direct
mapping in the concept table

## Usage

``` r
map2omop(
  db_con,
  codes,
  cdm_schema = NULL,
  collect = TRUE,
  translate_from = "CPT4"
)
```

## Arguments

- db_con:

  database connection object

- codes:

  vector of CPT4 codes

- cdm_schema:

  name of CDM schema

- collect:

  whether to return a dataframe (default) or sql query (Set to FALSE)

- translate_from:

  vocab to translate from. Can be a vector e.g., c("CPT4", "HCPCS")

## Value

a dataframe of icd, SNOMED, and OMOP concept codes
