


#' @title cpt2omop
#'
#' @description translates cpt codes to omop concept ID
#'
#' @param db_con database connection object
#' @param cdm_schema name of CDM schema
#' @param codes vector of CPT4 codes
#' @param collect whether to return a dataframe (default) or sql query (Set to FALSE)
#'
#' @return a dataframe of icd, SNOMED, and OMOP concept codes
#' @export
cpt2omop <- function(db_con,
                     codes,
                     cdm_schema = NULL,
                     collect = TRUE,
                     translate_from = "CPT4"){

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

  q = source_codes %>%
    dplyr::distinct() %>%
    dbplyr::sql_render()

  message("collecting...")

  out <- DBI::dbGetQuery(con, q)

  # DBI::dbRemoveTable(db_con, temp_tbl)

  if(isTRUE(collect)){
    return(out)
  } else {
    return(source_codes)
  }

}
