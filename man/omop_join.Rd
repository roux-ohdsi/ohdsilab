% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/omop_join.R
\name{omop_join}
\alias{omop_join}
\title{Join current query to another omop table}
\usage{
omop_join(
  data,
  table,
  type,
  by,
  suffix = c("_x", "_y"),
  con = getOption("con.default.value"),
  schema = NULL,
  x_as = NULL,
  y_as = NULL,
  ...
)
}
\arguments{
\item{data}{sql query from dbplyr/dplyr. this function works in pipes!}

\item{table}{the omop table (or other table in your schema) you wish to join}

\item{type}{the type of join. use types available in dplyr: left, right, inner, anti, full etc.}

\item{con}{defaults to the connection you set with options()}

\item{schema}{defaults to the schema you set with options()}

\item{x_as}{optional; a string for the name of the left table}

\item{y_as}{optional; a string for the name of the right table}

\item{...}{arguments passed on to the join function. e.g., by = "person_id"}
}
\value{
Continued dplyr query
}
\description{
Simple wrapper for join functions to join an existing query
to another table in the omop cdm (or any other of the same source).
}
\details{
If you are using omop_join with ohdsi_lab, you should include
the following two lines at the top of your script after setting the schema and connection, where
con refers to a connection generated by DatabaseConnector::connect() and cdm_schema points to
the cdm_schema for pharmetrics. To provide provide an alternative schema, see below.

options(con.default.value = con)

options(schema.default.value = cdm_schema)

There are a few good reasons to use omop_join() when possible over the x_join functions from dplyr.
First, it reduces the code necessary to join an existing table to another table. Second,
it includes checks/workarounds for two sources of common errors using dplyr with DatabaseConnector:
it automatically appends the x_as and y_as arguments to the join call if they are not provided and
it changes the default suffix from .x/.y to _x/_y for cases with shared column names not specified by
the \code{by} argument which will result in a sql error.

omop_join() can also be used to join tables in other schema - simply set the schema argument
to the preferred schema (whereas otherwise it just looks for the default).
}
\examples{
options(con.default.value = con)
options(schema.default.value = cdm_schema)
obs_tbl |>
  omop_join("person", type = "left", by = "person_id")

}
