
#' Connect to the ohdsilab redshift database
#'
#' @description
#' Helper function to connect to the ohdsilab OMOP database. You will need to
#' supply your redshift username and password (which you received in an email when
#' you first set up your workspace). The location of the CDM schema is set by default.
#'
#' The function will also set default values for your user schema, the cdm schema,
#' and the connection object, which are used by other functions in the ohdsilab package.
#' These can be found by running getOption("con.default.value"), getOption("schema.default.value"),
#' and getOption("write_schema.default.value").
#'
#' @param username your redshift username (required)
#' @param password your redshift password (required)
#' @param cdm_schema the omop cdm schema (set by default)
#'
#' @return a connection object
#' @export
#'
#' @examples
#'
#' \dontrun{
#' con <- ohdsilab_connect(
#'     username = keyring::key_get("db_username"),
#'     password = keyring::key_get("db_password")
#'     )
#' }
ohdsilab_connect <- function(username, password, cdm_schema = "omop_cdm_53_pmtx_202203"){
	usr = username
	pw  = password

	# DB Connections ===============================================================
	write_schema = paste0("work_", usr)

	# Create the connection
	con =  DatabaseConnector::connect(
		dbms = "redshift",
		server = "ohdsi-lab-redshift-cluster-prod.clsyktjhufn7.us-east-1.redshift.amazonaws.com/ohdsi_lab",
		port = 5439,
		user = usr,
		password = pw
	)
	if(isTRUE(DatabaseConnector::dbIsValid(con))){
		cat(cli::col_green("Connected Successfully"))
	} else{
		cat(cli::col_red("Error: Unable to connect to Database. Check credentials, internet, and VPN connections"))
	}

	# make it easier for some r functions to find the database

	on.exit(options(con.default.value = con))
	on.exit(options(schema.default.value = cdm_schema), add = TRUE)
	on.exit(options(write_schema.default.value = write_schema), add = TRUE)

	return(con)

}
