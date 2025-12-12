# Insert string

Useful for inserting periods in icd9 codes when they come without.

## Usage

``` r
str_insert(x, pos, insert)
```

## Arguments

- x:

  a character or character vector

- pos:

  after which position in the string to insert

- insert:

  what to insert

## Value

the character with the inserted string

## Examples

``` r
str_insert("100", 2, ".")
#> [1] "10.0"
```
