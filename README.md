
<br/>

### ohdsilab: Tools for using the Roux ohdsilab at Northeastern University.

<hr/>
<!-- badges: start -->
<!-- badges: end -->

The goals of the ohdsilab R package are two fold: (1) To streamline working with
the OHDSI-Lab data at the Roux Institute (and other OMOP CDM databases) and (2)
To provde an easier onramp for students and researchers new to working with the OMOP CDM or SQL 
databases. To do this, the package contains functions and template code snippets to facilitate easier use
of the Ohdsilab. These functions and snippits build on existing OHDSI R packages like
{DatabaseConnector} as well as standard R packages like {dplyr} and {tidyr}. The package also contains
a number of vingettes intended for R users who are new to OHDSI-Lab, the OMOP CDM, or working with 
data in SQL databases from R. 

## Installation

***For OHDSI-Lab users, we strongly recommend using the {renv} R package to install ohdsilab and
all other packages on your OHDSI-Lab Box/Workspace. Installation without {renv} is likely to fail
due to permission restrictions. A guide to using {renv} is here: https://rstudio.github.io/renv/articles/renv.html.***

Installation only needs to be done once, unless you are updating the package. 

```{r}
install.packages("remotes")
remotes::install_github("roux-ohdsi/ohdsilab")
```

or with {renv}:

```{r}
renv::install("roux-ohdsi/ohdsilab")
```

If you want to also install OHDSI packages (e.g., DatabaseConnector), set dependencies = "Suggests". This is recommended unless you are working on the AllofUs Researcher workbench as these packages take a while to install and are not terribly useful with the AllofUs database setup. 

```{r}
# using {remotes}
remotes::install_github("roux-ohdsi/ohdsilab", dependencies = "Suggests")
```




