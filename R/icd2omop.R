


#' @title icd2omop
#'
#' @param codes vector of source codes with or without wildcards
#' @param source_wildcard wildcard indicator in source codes. for example if code is R47.x, put "x"
#' @param dbms_wildcard wildcard indicator for dbms LIKE function.
#' @param translate_from source vocabulary, e.g., ICD9CM or ICD10CM. Make sure to enter the same way it is included in the concept table
#' @param collect whether to execute the query. defaults to TRUE
#' @param overwrite whether to overwrite the temp table created in the course of the query (#temp). defaults to TRUE
#' @param con the connection object to the database. defaults to option "con.default.value"
#' @param cdm_schema the schema containing the CDM. defaults to option "cdm_schema.default.value"


#' @return a dataframe of the target and source codes, and the original codes with wildcard (`orig_code`). If collect = FALSE, a reference to the SQL query.
#' @export
icd2omop <- function(codes,
                     source_wildcard = "x",
                     dbms_wildcard = "%",
                     translate_from = "ICD9CM",
                     collect = TRUE,
                     overwrite = TRUE,
                     con = getOption("con.default.value"),
                     cdm_schema = getOption("cdm_schema.default.value"),
                     ...){


  if (!is.null(cdm_schema)) {
    concept = paste0(cdm_schema, ".concept")
    concept_relationship = paste0(cdm_schema, ".concept_relationship")
  } else {
    concept = "concept"
    concept_relationship = "concept_relationship"
  }

  wild <- any(stringr::str_detect(codes, source_wildcard))

  if (wild) {
    codes_df <- data.frame(orig_code = codes,
                           orig_code_wild = stringr::str_replace_all(codes, paste0(source_wildcard, "+"), dbms_wildcard))

    tryCatch(
      dplyr::copy_to(dest = con, df = codes_df, name = "#temp",
                     temporary = TRUE, overwrite = TRUE),
      error = function(e) stop("Temporary table #temp already exists. If not needed, set `overwrite = TRUE`"))

    source_codes <- dplyr::tbl(con, concept) %>%
      dplyr::filter(vocabulary_id == translate_from) %>%
      dplyr::left_join(dplyr::tbl(con, "#temp"),
                       sql_on = "concepts.concept_code LIKE my.orig_code_wild",
                       x_as = "concepts", y_as = "my") %>%
      dplyr::filter(!is.na(orig_code_wild)) %>%
      dplyr::select(concept_id, source_concept_name = concept_name, source_vocabulary_id = vocabulary_id,
                    source_code = concept_code, orig_code_wild, orig_code)
  } else {
    source_codes <- dplyr::tbl(con, concept) %>%
      dplyr::filter(vocabulary_id == translate_from, concept_code %in% codes) %>%
      dplyr::select(concept_id, source_concept_name = concept_name, source_vocabulary_id = vocabulary_id,
                    source_code = concept_code)
  }

  target_codes <- dplyr::tbl(con, concept) %>%
    dplyr::filter(standard_concept = "S") %>%
    dplyr::select(concept_id, target_concept_name = concept_name, target_vocabulary_id = vocabulary_id)

  relationships <- dplyr::tbl(con, concept_relationship) %>%
    dplyr::filter(relationship_id == "Maps to") %>%
    dplyr::inner_join(source_codes, by = c("concept_id_1" = "concept_id"), x_as = "relationships", y_as = "source") %>%
    dplyr::inner_join(target_codes, by = c("concept_id_2" = "concept_id"), y_as = "target") %>%
    dplyr::rename(concept_id = concept_id_2,
                  orig_concept_id = concept_id_1) %>%
    dplyr::select(-any_of("orig_code_wild")) %>%
    dplyr::distinct()

  if (collect) dbi_collect(relationships)
}

