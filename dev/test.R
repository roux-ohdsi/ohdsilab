# ==============================================================================
# Packages =====================================================================
library(keyring)
library(DatabaseConnector)
library(tidyverse)
library(ohdsilab)

# Credentials ==================================================================
usr = keyring::key_get("lab_user")
pw  = keyring::key_get("lab_password")

# DB Connections ===============================================================
base_url = "https://atlas.roux-ohdsi-prod.aws.northeastern.edu/WebAPI"
cdm_schema = "omop_cdm_53_pmtx_202203"
my_schema = paste0("work_", keyring::key_get("lab_user"))
# Create the connection
con =  DatabaseConnector::connect(
	dbms = "redshift",
	server = "ohdsi-lab-redshift-cluster-prod.clsyktjhufn7.us-east-1.redshift.amazonaws.com/ohdsi_lab",
	port = 5439,
	user = keyring::key_get("lab_user"),
	password = keyring::key_get("lab_password")
)
class(con)
# make it easier for some r functions to find the database
options(con.default.value = con)
options(schema.default.value = cdm_schema)

# End Setup ====================================================================
# ==============================================================================

tbl(con, inDatabaseSchema(my_schema, "hiv_blom")) |>
	omop_join2("condition_occurrence", type = "inner", by = c("subject_id" = "person_id")
						 , x_as = "p1", y_as = "p2"
						 ) |>
	show_query()
