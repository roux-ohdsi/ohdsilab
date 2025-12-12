# List the current files in your bucket.

List the current files in your bucket.

## Usage

``` r
aou_ls_bucket(pattern = "*.csv", bucket_name = Sys.getenv("WORKSPACE_BUCKET"))
```

## Arguments

- pattern:

  pattern like \*.csv or a single file name e.g., mydata.csv

- bucket_name:

  name of your bucket. Recommend leaving the default

- description:

  Quick function to list files matching a pattern in your bucket
