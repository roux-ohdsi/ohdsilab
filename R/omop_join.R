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
#' @param con defaults to the connection you set with options()
#' @param schema defaults to the schema you set with options()
#' @param ... arguments passed on to the join function. e.g., by = "person_id"
#' @param x_as optional; a string for the name of the left table
#' @param y_as optional; a string for the name of the right table
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
											by,
											suffix = c("_x", "_y"),
                      con = getOption("con.default.value"),
                      schema = NULL,
                      x_as = NULL,
											y_as = NULL,
											...){

  if (is.null(con)) stop("Provide `con` as an argument or default with `options(con.default.value = ...)`")

	# allow for use in AoU
  # first argument assigns the schema as a default, or NULL if not set
  # second if adds a period to the schema
  if (is.null(schema)) schema <- getOption("schema.default.value")
  if (!is.null(schema)) schema <- paste0(schema, ".")

  y_table = tbl(con, paste0(schema, table))
  shared_columns = intersect(colnames(data), colnames(y_table))

  # stop("Provide `schema` as an argument or default with `options(schema.default.value = ...)`")

  if(!all(sort(shared_columns) == sort(by)) & all(suffix == c("_x", "_y"))){
  	w1 = "There are shared column names not specified in the `by` argument."
  	w2 = "These column names now include `_x` and `_y`."
  	w3 = "You can change this suffix using the `suffix` argument but it cannot contain periods (`.`)."
  	w4 = "Consider specifing all shared columns in the `by` argument."
  	w5 = "Or if these additional shared columns are `NA`, remove them prior to joining."
  	warning(paste(w1, w2, w3, w4, w5, sep = "\n  "))
  }

  get(paste(type, "join", sep = "_"))(data, y_table,
  																		x_as = if (missing(x_as)) {paste(sample(letters, 10, TRUE), collapse = "")} else {x_as},
  																		y_as = if (missing(y_as)) {paste(sample(letters, 10, TRUE), collapse = "")} else {y_as},
  																		by = by,
  																		suffix = suffix,
  																		...)

}
