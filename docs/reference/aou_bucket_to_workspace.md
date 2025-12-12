# Move files from a bucket to your workspace

This step retrieves a file you have saved permanently in your bucket
into your workspace where you can read it into R using a function like
write.csv().

## Usage

``` r
aou_bucket_to_workspace(files, bucket_name = Sys.getenv("WORKSPACE_BUCKET"))
```

## Arguments

- files:

  The name of a file in your bucket or a vector of multiple files.

- bucket_name:

  Name of your bucket. Recommend leaving the default
