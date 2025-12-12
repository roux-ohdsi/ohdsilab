# Function to Install and Load R Packages

Function to Install and Load R Packages

## Usage

``` r
bookstore(package_names, quietly = TRUE)
```

## Arguments

- package_names:

  a character vector of package names from CRAN or github

- description:

  The bookstore() function will check to see if packages provided are
  already installed on the local machine. If not installed, it will look
  for the package on CRAN and install it if found. If it doesn't find
  the package on CRAN, it'll ask for the owner/repository_name from
  github to install the package from github. this input should be
  provided without quotes. For example, respond with roux-ohdsi/ohdsilab
  NOT "roux-ohdsi/ohdsilab".

## Examples

``` r
if (FALSE) { # \dontrun{
bookstore(c("aouFI", "CohortGenerator", "tidyr"))
} # }
```
