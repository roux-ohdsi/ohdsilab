


#' @title icd2omop2
#'
#' @description this function will only find exact ICD matches. It is faster than
#' icd2omop() because it does not need to use a join to find wildcards. It also does not
#' return a match with the beginning icd codes however. It is important to check that
#' all codes searched have found a match
#'
#' @param db_con database connection object
#' @param codes vector of ICD codes with or without wildcards
#' @param icd_wildcard wordcard indicator in icd codes. for example if code is R47.x, put "x"
#' @param cdm_schema name of CDM schema
#' @param translate_from ICD codes to start
#' @param translate_to codes to transfer to to get to omop. usually SNOMED
#' @param dbms_wildcard wildcard indicator for dbms SIMILAR TO function.
#'
#' @return a dataframe of icd, SNOMED, and OMOP concept codes
icd2omop2 <- function(db_con,
                     codes,
                     cdm_schema = NULL,
                     icd_wildcard = "x",
                     dbms_wildcard = "%",
                     translate_from = "ICD9CM",
                     translate_to = "SNOMED"){

  if(!is.null(cdm_schema)){
    concept = paste0(cdm_schema, ".concept")
    concept_relationship = paste0(cdm_schema, ".concept_relationship")
  } else {
    concept = "concept"
    concept_relationship = "concept_relationship"
  }

  source_codes <- dplyr::tbl(db_con, concept) %>%
    dplyr::filter(vocabulary_id == translate_from) %>%
    dplyr::filter(concept_code %in% !!codes) %>%
    dplyr::select(concept_id, source_concept_name = concept_name, source_vocabulary_id = vocabulary_id,
                  source_code = concept_code)

  message("got source codes")

  target_codes <- dplyr::tbl(db_con, concept) %>%
    dplyr::filter(vocabulary_id == translate_to) %>%
    dplyr::select(concept_id, target_concept_name = concept_name, target_vocabulary_id = vocabulary_id)

  message("got target codes")


  relationships <- dplyr::tbl(db_con, concept_relationship)   %>%
    dplyr::filter(relationship_id == "Maps to")

  relationships <- source_codes %>%
    left_join(relationships, by = c("concept_id" = "concept_id_1"), y_as = "relationships", x_as = "source") %>%
    dplyr::inner_join(target_codes, by = c("concept_id_2" = "concept_id"), y_as = "target") %>%
    dplyr::rename(concept_id = concept_id_2,
                  orig_concept_id = concept_id_1)

  message("got relationships ")


  q = relationships %>%
    dplyr::distinct() %>%
    dbplyr::sql_render()

  message("collecting...")

  out <- DBI::dbGetQuery(con, q)

  # DBI::dbRemoveTable(db_con, temp_tbl)

  return(out)

}
