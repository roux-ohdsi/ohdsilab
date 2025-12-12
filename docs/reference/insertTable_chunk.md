# Insert a table to your user schema in chunks because speed and bugs

Insert a table to your user schema in chunks because speed and bugs

## Usage

``` r
insertTable_chunk(
  data,
  table_name,
  n = 100,
  overwrite = TRUE,
  con = getOption("con.default.value"),
  write_schema = getOption("write_schema.default.value"),
  ...
)
```

## Arguments

- data:

  data you want to write to your user schema

- table_name:

  the name of the table that you want to write to the database

- n:

  the number of chunks to split. defaults to 100. Aim for \< 200 rows
  per chunk right now.

- overwrite:

  do you want to overwrite an existing table of the same name?

- con:

  connection. defaults to the set option if done.

- ...:

  additional arguments to be passed along to
  DatabaseConnector::insertTable

- user_schema:

  your user schema. defaults to the set option if done

## Examples

``` r
if (FALSE) { # \dontrun{
options(con.default.value = con)
write_schema = paste0("work_", keyring::key_get("db_username"))
insertTable_chunk(data = data, table_name = "table1", n = 50, overwrite = TRUE, user_schema = write_schema)
} # }
```
