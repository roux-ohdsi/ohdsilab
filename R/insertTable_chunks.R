#' Insert a table to your user schema in chunks because speed and bugs
#'
#' @param data data you want to write to your user schema
#' @param n the number of chunks to split. defaults to 100. Aim for < 200 rows per chunk right now.
#' @param table_name the name of the table that you want to write to the database
#' @param overwrite do you want to overwrite an existing table of the same name?
#' @param con connection. defaults to the set option if done.
#' @param user_schema your user schema. defaults to the set option if done
#' @param ... additional arguments to be passed along to DatabaseConnector::insertTable
#'
#' @export
#'
#' @examples
#' \dontrun{
#' options(con.default.value = con)
#' my_schema = paste0("work_", keyring::key_get("lab_user"))
#' insertTable_chunk(data = data, n = 50, table_name = "table1", overwrite = TRUE, user_schema = my_schema)
#' }
insertTable_chunk <- function(data, n = 100,  table_name,
                              overwrite = TRUE,
                              con = getOption("con.default.value"),
                              user_schema,
                              ...){

  df_head = head(data, 1)
  df_tail = tail(data, -1)

  num_groups = n

  df_nest <- df_tail |>
      dplyr::group_by((dplyr::row_number()-1) %/% (n()/num_groups)) |>
      tidyr::nest() |>  dplyr::pull(data)

  if(isTRUE(overwrite)){
    drop = TRUE
    create = TRUE
  }

  suppressMessages(
    DatabaseConnector::insertTable(connection = con,
                                       databaseSchema = user_schema,
                                       data = df_head,
                                       tableName = table_name,
                                       dropTableIfExists = drop,
                                       createTable = create
                                       )
    )

    cat("Wrote first row. Remaining progress: \n")

      pb = txtProgressBar(min = 0, max = num_groups, initial = 0, style = 3, char = "=", width = 60)

      for(i in 1:length(df_nest)){
        suppressMessages(
          DatabaseConnector::insertTable(connection = con,
                                         databaseSchema = user_schema,
                                         tableName = table_name,
                                         dropTableIfExists = FALSE,
                                         createTable = FALSE,
                                         data = df_nest[[i]]
                                         )
        )
        setTxtProgressBar(pb,i)

      }
      close(pb)

}