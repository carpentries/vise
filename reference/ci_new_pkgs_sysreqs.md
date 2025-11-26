# convert a list of packages into a description file and detect system requirements

This function converts a set of R package names to a description file
and then passes this to
[`ci_sysreqs()`](https://zkamvar.github.io/vise/reference/ci_sysreqs.md)
for system requirements detection.

## Usage

``` r
ci_new_pkgs_sysreqs(pkgs, ...)
```

## Arguments

- pkgs:

  the list of packages, each an element with a `package` field

- ...:

  extra options to be passed to ci_sysreqs()\`

## Examples

``` r
Sys.setenv(R_USER_CACHE_DIR = tempfile())

pkgs <- list(list(package = "knitr", package = "rmarkdown"))
if (startsWith(tolower(R.version$os), "linux")) {
  vise::ci_new_pkgs_sysreqs(pkgs, execute = FALSE)
}
#> [1] "ubuntu" "24.04" 
#> character(0)
```
