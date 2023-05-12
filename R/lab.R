

lab_set_password <- function() {
  keyring::key_set("lab_user", prompt = "Username for this workspace")
  keyring::key_set("lab_password", prompt = "Password for this workspace")
}

lab_get_password <- function() {
  keyring::key_get("lab_password")
}

lab_connection_details <- function() {
  DatabaseConnector::createConnectionDetails(dbms = "redshift",
                                             server = "ohdsi-lab-redshift-cluster-prod.clsyktjhufn7.us-east-1.redshift.amazonaws.com/ohdsi_lab",
                                             port = 5439,
                                             user = keyring::key_get("lab_user"),
                                             password = keyring::key_get("lab_password")
  )
}

lab_connect <- function() {
  DatabaseConnector::connect(dbms = "redshift",
                             server = "ohdsi-lab-redshift-cluster-prod.clsyktjhufn7.us-east-1.redshift.amazonaws.com/ohdsi_lab",
                             port = 5439,
                             user = keyring::key_get("lab_user"),
                             password = keyring::key_get("lab_password")
  )
}

lab_authorize_atlas <- function() {
  ROhdsiWebApi::authorizeWebApi(lab_atlas_url(),
                                authMethod = "db",
                                webApiUsername = keyring::key_get("lab_user"),
                                webApiPassword = keyring::key_get("lab_password"))
}

lab_atlas_url <- function() {
  return("https://atlas.roux-ohdsi-prod.aws.northeastern.edu/WebAPI")
}

lab_cdm_schema <- function() {
  return("omop_cdm_53_pmtx_202203")
}


lab_write_schema <- function() {
  paste0("work_", keyring::key_get("lab_user"))
}
