# KRD - Generating a cohort

This tutorial outlines the process of generating a cohort from the
Komodo Research Dataset stored within the OHDSI Lab. For the following
code to function, you must be logged into an OHDSI Lab workspace. This
tutorial assumes you have already successfully connected to the OHDSI
Lab’s Amazon Redshift database according to the instructions in the
previous article “General - Connecting to the database”.

Install and load the additional necessary packages.

``` r
install.packages(c("dplyr", "lubridate", "pak"))
pak::pak("roux-ohdsi/ohdsilab")

library(dplyr)
library(ohdsilab)
```

Set Komodo Research Dataset schema and your personal write schema

``` r
komodo_schema <- "komodo_ext"
write_schema <- paste0(
  "work_",
  keyring::key_get("db_username"))
```

The next steps will illustrate the process of creating a cohort of
patients who have been diagnosed with type 2 diabetes, prescribed
metformin within one month after their type 2 diabetes diagnosis, and
undergone metabolic surgery within 6 months after their type 2 diabetes
diagnosis.

Because querying the dataset can be a lengthy process (due to it’s large
patient count), it’s recommended that you identify the exact syntax of
each clinical concept (drug, condition, procedure, etc) before
generating your cohort in R. A quick way to determine syntax is to run a
simple limited SQL query using the DBeaver application within every
OHDSI Lab Workspace (e.g., SELECT generic_name FROM
komodo_ext.pharmacy_events WHERE generic_name LIKE “%METFORMIN%” LIMIT
5), which will tell you quickly whether the codes/concepts you are
looking for exist in the dataset.

Get patient ids and diagnosis dates for all type 2 diabetes episodes
(using the ICD-10 code E11 and all its descendants). Diagnosis data are
stored in several fields within the Komodo Research Dataset. The
k_get_condition_events function was designed to retrieve these data
cleanly.

``` r
t2d_events <- ohdsilab::k_get_condition_events(
  con,
  codes = c("E11%"))
```

Get patient ids and procedure dates for all metabolic surgery episodes
(using the CPT codes 43644 and 43775). Procedure data are stored in
several fields within the Komodo Research Dataset. The
k_get_procedure_events function was designed to retrieve these data
cleanly.

``` r
metabolic_surgery_events <- ohdsilab::k_get_procedure_events(
  con,
  codes = c("43644", "43775"))
```

Load the the pharmacy table and filter for metformin events. Medication
data are stored in several fields within the Komodo Research Dataset,
however, “generic_name” covers nearly all medication records, so no
custom function is needed.

``` r
metformin_events <- tbl(con, inDatabaseSchema(komodo_schema, "pharmacy_events")) |>
  filter(generic_name == "METFORMIN HCL") |>
  select(patient_id, date_prescription_written)
```

Create a cohort using combining data from the above lazy tables

``` r
t2d_cohort <- t2d_events |>
  group_by(patient_id) |>
  summarize(index_date = min(diagnosis_date)) |>
  inner_join(metformin_events, by = "patient_id") |>
  filter(date_prescription_written >= index_date,
         date_prescription_written <= index_date + 30L) |>
  distinct(patient_id, index_date) |>
  inner_join(metabolic_surgery_events, by = "patient_id") |>
  filter(procedure_date >= index_date,
         procedure_date <= index_date + 180L) |>
  distinct(patient_id, index_date)
```

Save the cohort to a table in your write_schema for future access. This
step may take a while to run (e.g., this cohort took 58 minutes)
depending on cohort complexity and size of data scanned, but once saved,
your cohort can be accessed quickly without needing to run the above
code again. Make sure to give your cohorts different names (e.g. this
one’s called “.t2d_cohort”) so that you don’t accidentally overwrite one
when running this step for additional cohorts.

``` r
DatabaseConnector::executeSql(
  con,
  paste0(
    "DROP TABLE IF EXISTS ", write_schema, ".t2d_cohort;
   CREATE TABLE ", write_schema, ".t2d_cohort AS ",
    dbplyr::sql_render(t2d_cohort)
  ))
```

You now have a cohort of distinct patient_ids and the date when they
first entered your cohort (index date). Your cohort can be joined to
other Komodo Research Dataset tables for information about those
patients’ medical history, providers, insurance, etc.
