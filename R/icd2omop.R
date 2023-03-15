


#' @title icd2omop
#'
#' @param db_con database connection object
#' @param schema if there is a database schema, TRUE. defaults of FALSE
#' @param schema.name name of databsae schema. only required if schema is TRUE
#' @param codes vector of ICD codes with or without wildcards
#' @param icd_wildcard wordcard indicator in icd codes. for example if code is R47.x, put "x"
#' @param dbms_wildcard wildcard indicator for dbms SIMILAR TO function.
#' @param icd_version ICD9CM or ICD10CM. Make sure to enter the same way it is included in the concept table
#'
#' @return a dataframe of icd, SNOMED, OMOP concept codes, and the original codes to be matched (`orig_code`)
#' @export
icd2omop <- function(db_con,
                     codes,
                     cdm_schema = NULL,
                     write_schema = NULL,
                     icd_wildcard = "x",
                     dbms_wildcard = "%",
                     translate_from = "ICD9CM",
                     translate_to = "SNOMED",
                     overwrite = FALSE){

  codes_df <- data.frame(orig_code = codes,
                         orig_code_wild = stringr::str_replace_all(codes, paste0(icd_wildcard, "+"), dbms_wildcard))

  if(!is.null(cdm_schema)){
    concept = paste0(cdm_schema, ".concept")
    concept_relationship = paste0(cdm_schema, ".concept_relationship")
  } else {
    concept = "concept"
    concept_relationship = "concept_relationship"
  }

  if(!is.null(write_schema)){
    temp_tbl = paste0(write_schema, ".xzxzxzxzxzx")
  } else {
    temp_tbl = "xzxzxzxzxzx"
  }

  tryCatch(
    dplyr::copy_to(dest = db_con, df = codes_df, name = temp_tbl,
          temporary = FALSE, overwrite = overwrite),
    error = function(e) stop("Table xzxzxzxzxzx already exists. If not needed, set `overwrite = TRUE`"))

  source_codes <- dplyr::tbl(db_con, concept) %>%
    dplyr::filter(vocabulary_id == translate_from) %>%
    dplyr::left_join(dplyr::tbl(db_con, temp_tbl),
                     sql_on = "concepts.concept_code LIKE my.orig_code_wild",
                     x_as = "concepts", y_as = "my") %>%
    dplyr::filter(!is.na(orig_code_wild)) %>%
    dplyr::select(concept_id, source_concept_name = concept_name, source_vocabulary_id = vocabulary_id,
           source_code = concept_code, orig_code_wild)

  target_codes <- dplyr::tbl(db_con, concept) %>%
    dplyr::filter(vocabulary_id == translate_to) %>%
    dplyr::select(concept_id, target_concept_name = concept_name, target_vocabulary_id = vocabulary_id)

  relationships <- dplyr::tbl(db_con, concept_relationship) %>%
    dplyr::filter(relationship_id == "Maps to") %>%
    dplyr::inner_join(source_codes, by = c("concept_id_1" = "concept_id"), x_as = "relationships", y_as = "source") %>%
    dplyr::inner_join(target_codes, by = c("concept_id_2" = "concept_id"), y_as = "target") %>%
    dplyr::rename(concept_id = concept_id_2,
           orig_concept_id = concept_id_1) %>%
    dplyr::collect()

  DBI::dbRemoveTable(db_con, temp_tbl)

  relationships %>%
    dplyr::left_join(codes_df, by = "orig_code_wild", multiple = "all") %>%
    dplyr::select(-orig_code_wild) %>%
    dplyr::distinct()

}

