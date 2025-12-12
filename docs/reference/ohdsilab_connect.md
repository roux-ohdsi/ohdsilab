# Connect to the ohdsilab redshift database

Helper function to connect to the ohdsilab OMOP database. You will need
to supply your redshift username and password (which you received in an
email when you first set up your workspace). The location of the CDM
schema is set by default.

The function will also set default values for your user schema, the cdm
schema, and the connection object, which are used by other functions in
the ohdsilab package. These can be found by running
getOption("con.default.value"), getOption("schema.default.value"), and
getOption("write_schema.default.value").

## Usage

``` r
ohdsilab_connect(username, password, cdm_schema = "omop_cdm_53_pmtx_202203")
```

## Arguments

- username:

  your redshift username (required)

- password:

  your redshift password (required)

- cdm_schema:

  the omop cdm schema (set by default)

## Value

a connection object

## Examples

``` r
if (FALSE) { # \dontrun{
con <- ohdsilab_connect(
    username = keyring::key_get("db_username"),
    password = keyring::key_get("db_password")
    )
} # }
```
