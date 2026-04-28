# General - Connecting to the database

This tutorial outlines the process of connecting to the OHDSI Lab’s
Amazon Redshift database from within an OHDSI Lab Workspace.

Install and load the two necessary packages (keyring and
DatabaseConnector).

``` r
install.packages(c("keyring", "DatabaseConnector"))

library(keyring)
library(DatabaseConnector)
```

Set your database credentials. This step only needs to be completed once
per Workspace. Your credentials will be saved between R sessions.

``` r
key_set("db_username")
key_set("db_password")
```

From within your OHDSI Lab Workspace, open Google Chrome, and navigate
to
<https://docs.aws.amazon.com/redshift/latest/mgmt/jdbc20-download-driver.html>
or Google “Redshift JDBC driver” and click on the first link. Click the
download link labeled “JDBC 4.2–compatible driver version 2.x and AWS
SDK driver–dependent libraries”. When it finishes downloading, move the
file to a folder of your choosing and extract it by right-clicking on
it, and selecting “extract all”.

Finally, within the extracted contents, add a prefix of “ND” to the file
names of “redshift-2.40.5.jar” and “redshiftserverless-2.40.5.jar” so
that the only file that starts with the word “redshift” is
“redshift-jdbc42-2.2.5.jar”. Occasionally, R has trouble locating this
file if the other two files also start with “redshift” so this renaming
helps avoid that.

Point your R analysis toward your extracted redshift jdbc driver file.

``` r
Sys.setenv("DATABASECONNECTOR_JAR_FOLDER" = "insert path to jdbc driver here")
```

Set the database connection details

``` r
connectionDetails <- createConnectionDetails(
  dbms = "redshift",
  server = "ohdsi-lab-redshift-cluster-prod.clsyktjhufn7.us-east-1.redshift.amazonaws.com/ohdsi_lab",
  port = 5439,
  user = keyring::key_get("db_username"),
  password = keyring::key_get("db_password"))
```

Connect to the database. If successful, a connection should appear in
the “Connections” pane of RStudio (top right) labeled “ohdsilab”. You
can click on the drop down arrow beside the connection to explore the
database schemas, tables, and fields.

``` r
con <- connect(connectionDetails)
```

You now have access to the OHDSI Lab and its contained datasets. Review
additional articles for information on how to build a cohort, how to
generate a table one, and more.
