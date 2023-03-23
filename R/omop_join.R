#' Join current query to another omop table
#'
#' @description Simple wrapper for join functions to join an existing query
#' to another table in the omop cdm (or any other of the same source). Include
#' the following two lines at the top of your script after setting the schema and connection
#'
#' `options(con.default.value = connection_variable_name)`
#'
#' `options(schema.default.value = cdm_schema_variable_name)`
#'
#' @param data sql query from dbplyr/dplyr. this function works in pipes!
#' @param table the omop table (or other table in your schema) you wish to join
#' @param type the type of join. use types available in dplyr: left, right, inner, anti, full etc.
#' @param con defaults to the connection you set with options(). does not need to be specified
#' @param schema defaults to the schema you set with options(). does not need to be specified.
#' @param ... arguments passed on to the join function. e.g., by = "person_id"
#'
#' @return more sql query info stuff
#' @export
#' @md
#'
#' @examples
#' options(con.default.value = con)
#' options(schema.default.value = cdm_schema)
#' obs_tbl |>
#'   omop_join("person", type = "left", by = "person_id")
#'
omop_join <- function(data,
                      table,
                      type,
                      con = getOption("con.default.value"),
                      schema = getOption("schema.default.value"),
                      ...){
  if(is.null(con) | is.null(schema)){stop("Remember to set the connection and schema defaults. see ?omop_join for details")}
  get(paste(type, "join", sep = "_"))(data, tbl(con, paste(schema, table, sep = ".")), ...)
}
