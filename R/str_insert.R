#' Insert string
#'
#'@description Useful for inserting periods in icd9 codes when they come without.
#'
#' @param x a character or character vector
#' @param pos what position in the string to insert
#' @param insert what to insert
#'
#' @return
#' @export
#'
#' @examples
str_insert <- function(x, pos, insert) {       # Create own function

  gsub(paste0("^(.{", pos, "})(.*)$"),
       paste0("\\1", insert, "\\2"),
       x)
}


#' Add periods to icd numbers
#'
#' @description Useful for when icd9 numbers come without periods
#'
#' @param data dataframe or tibble
#' @param icd_column name of column to fix
#' @param overwrite whether to overwrite supplied column of add a new one
#'
#' @return the same dataframe overwriting the column with icd9
#' @export
#'
#' @examples
icd9_periods <- function(data, icd_column, overwrite = TRUE){


  if(isTRUE(overwrite)){
    data %>%
      mutate(
        {{icd_column}} := as.character({{icd_column}}),
        {{icd_column}} :=
               ifelse(nchar({{icd_column}} > 3),
                      str_insert({{icd_column}}, 3, "."),
                      {{icd_column}})
             )
  } else {
    data %>%
      mutate(
        "{{icd_column}}_fix" := as.character({{icd_column}}),
        "{{icd_column}}_fix" :=
          ifelse(nchar({{icd_column}} > 3),
                 str_insert({{icd_column}}, 3, "."),
                 {{icd_column}})
      )

  }

}
