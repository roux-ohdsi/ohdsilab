


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
#' @return a dataframe of icd, SNOMED, and OMOP concept codes
#' @export
icd2omop <- function(db_con,
                     schema = FALSE,
                     codes,
                     schema.name = NA,
                     icd_wildcard = "x",
                     dbms_wildcard = "%",
                     icd_version = "ICD9CM"){

  exact_codes = codes[which(stringr::str_detect(codes, icd_wildcard, negate = TRUE))]
  wild_codes = codes[which(stringr::str_detect(codes, icd_wildcard, negate = FALSE))]
  wild_codes = stringr::str_remove_all(wild_codes, icd_wildcard)
  wild_codes = paste0(wild_codes, dbms_wildcard)

  all_codes = paste0("(",paste(c(exact_codes, wild_codes), collapse = "|"), ")")

  if(isTRUE(schema)){
    concept = paste0(schema.name, ".concept")
    concept_relationship = paste0(schema.name, ".concept_relationship")
  } else {
    concept = "concept"
    concept_relationship = "concept_relationship"
  }

  source_codes <- dplyr::tbl(db_con, concept) %>%
    dplyr::filter(vocabulary_id == icd_version,
           concept_code %SIMILAR TO% all_codes,
           #grepl(all_codes, concept_code, ignore.case = TRUE)
    ) %>%
    dplyr::select(concept_id, source_concept_name = concept_name, source_vocabulary_id = vocabulary_id,
           source_code = concept_code)

  target_codes <- dplyr::tbl(db_con, concept) %>%
    dplyr::filter(vocabulary_id == "SNOMED") %>%
    dplyr::select(concept_id, target_concept_name = concept_name, target_vocabulary_id = vocabulary_id)

  relationships <- dplyr::tbl(db_con, concept_relationship) %>%
    dplyr::filter(relationship_id == "Maps to") %>%
    dplyr::inner_join(source_codes, by = c("concept_id_1" = "concept_id")) %>%
    dplyr::inner_join(target_codes, by = c("concept_id_2" = "concept_id")) %>%
    dplyr::rename(concept_id = concept_id_2,
           orig_concept_id = concept_id_1) %>%
    dplyr::collect()

  return(relationships)
}
