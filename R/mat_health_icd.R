


#' Maternal Health ICD replication codes
#'
#' @return dataframe of icd codes
#' @export
#'
#' @examples
#' mat_health_icd()
mat_health_icd <- function(){

  bl_cov = tibble::tribble(
    ~label,                             ~icd,
    'Overweight/obesity',	            '278.0x, 649.1x, v85.3x, v85.4x',
    'Tobacco use disorder',             '305.1x, 649.0x, 989.84, v15.82',
    'Alcohol abuse or dependence',	    '291.xx, 303.xx, 305.0x, 357.5x, 425.5x, 571.0x, 571.1x, 571.2x, 571.3x, E860.0x, v11.3',
    'Male infertility',		            '606.x',
    'Female Infertility',               '628, 628.1, 628.2, 628.3, 628.4, 628.8',
    'Unspecified', 		                '628.9',
    'Polycystic ovarian syndrome',		'256.4'
  ) |>
    tidytext::unnest_tokens(icd, icd, token = "regex", pattern = ",") |>
    dplyr::mutate(icd = stringr::str_trim(icd), type = "baseline covariates")

  nn_outcomes = tibble::tribble(
    ~label,                             ~icd,
    'Multiple gestation', 	 	        'v27.2x, v27.3x, v27.5x, v27.6x, v31.xx,v32.xx,v33.xx,v34.xx,v35.xx,v36.xx, v37.xx, 651.xx, 652.6x, 660.5x, 662.3x, 761.5x',
    'Small for gestational age',	    '656.5x, 764.0x, 764.1x, 764.9x',
    'Large for gestational age',	    '766.0, 766.1, 656.6'
  )|>
    tidytext::unnest_tokens(icd, icd, token = "regex", pattern = ",") |>
    dplyr::mutate(icd = stringr::str_trim(icd), type = "neonatal outcomes")

  mat_outcomes = tibble::tribble(
    ~label,                          ~icd,
    'Gestational diabetes',           '648.8x, 250.xx, 648.0x, 250.xx',
    'Preeclampsia',                   '642.4x, 642.5x, 642.6x, 642.7x',
    'Gestational hypertension',       '642.3x'
  )|>
    tidytext::unnest_tokens(icd, icd, token = "regex", pattern = ",") |>
    dplyr::mutate(icd = stringr::str_trim(icd), type = "maternal outcomes")

  all_icd = dplyr::bind_rows(bl_cov, nn_outcomes, mat_outcomes) |>
    dplyr::rename(Code = icd) |>
    dplyr::mutate(CodeType = "ICD9", vocabulary_id = "ICD9CM")


  return(all_icd)



}
