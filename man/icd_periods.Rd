% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/str_insert.R
\name{icd_periods}
\alias{icd_periods}
\title{Add periods to icd numbers}
\usage{
icd_periods(data, icd_column, overwrite = TRUE)
}
\arguments{
\item{data}{dataframe or tibble}

\item{icd_column}{name of column to fix}

\item{overwrite}{whether to overwrite supplied column of add a new one}
}
\value{
the same dataframe overwriting the column with icd9
}
\description{
Useful for when icd9 numbers come without periods
}
