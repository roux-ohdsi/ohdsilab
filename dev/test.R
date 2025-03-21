# ==============================================================================
# Packages =====================================================================
library(keyring)
library(DatabaseConnector)
library(tidyverse)
library(ohdsilab)

# Credentials ==================================================================
usr = keyring::key_get("db_username")
pw  = keyring::key_get("db_password")

# DB Connections ===============================================================
base_url = "https://atlas.roux-ohdsi-prod.aws.northeastern.edu/WebAPI"
cdm_schema = "omop_cdm_53_pmtx_202203"
my_schema = paste0("work_", keyring::key_get("db_username"))
# Create the connection
con =  DatabaseConnector::connect(
	dbms = "redshift",
	server = "ohdsi-lab-redshift-cluster-prod.clsyktjhufn7.us-east-1.redshift.amazonaws.com/ohdsi_lab",
	port = 5439,
	user = keyring::key_get("db_username"),
	password = keyring::key_get("db_password")
)
class(con)
# make it easier for some r functions to find the database
options(con.default.value = con)
options(schema.default.value = cdm_schema)

# End Setup ====================================================================
# ==============================================================================

tbl(con, inDatabaseSchema(my_schema, "hiv_blom")) |>
	rename(person_id = subject_id) |>
	omop_join("condition_occurrence", type = "inner", by = "person_id") |>
	omop_join("person", by = "person_id", type = "inner", suffix = c("_a", "_b"))

tbl(con, inDatabaseSchema(cdm_schema, "person")) |>
	filter(year_of_birth == 2002, gender_source_value == "F") |>
	select(person_id) |>
	omop_join("condition_occurrence", type = "inner", by = "person_id")

c1 = colnames(tbl(con, inDatabaseSchema(cdm_schema, "condition_occurrence")))
c2 = colnames(tbl(con, inDatabaseSchema(cdm_schema, "person")))

c1[which(c1 %in% c2)]
c2[which(c2 %in% c1)]

intersect(c1, c2)
