# detect and execute system requirements from a lockfile

This function converts a renv lockfile to a description file and then
determines the system requirements via
[`pak::pkg_sysreqs()`](https://pak.r-lib.org/reference/pkg_sysreqs.html)
using the RStudio online resource. This is intended to be run on
continuous integration, so will error on MacOS and Windows

## Usage

``` r
ci_sysreqs(
  lockfile,
  execute = TRUE,
  sudo = TRUE,
  exclude = c("git", "make", "pandoc"),
  use_pak = FALSE
)
```

## Arguments

- lockfile:

  the path to a renv lockfile

- execute:

  if `TRUE` (default), the commands from
  [`pak::pkg_sysreqs()`](https://pak.r-lib.org/reference/pkg_sysreqs.html)
  will be executed via
  [`base::system()`](https://rdrr.io/r/base/system.html).

- sudo:

  if `TRUE` (default), the command runs as root

- exclude:

  packages to exclude from installation because they already exist on
  the system.

- use_pak:

  if `TRUE`, use the `pak` package to determine system requirements.
  Else, remotes.

## Value

a vector of exectutible system calls to install the dependencies

## Examples

``` r
lock <- system.file("renv.lock", package = "vise")

# The system requirements for a typical {knitr} installation
if (startsWith(tolower(R.version$os), "linux")) {
  print(vise::ci_sysreqs(lock, execute = FALSE))
}
#> [1] "ubuntu" "24.04" 
#> [1] "apt-get install -y make"       "apt-get install -y pandoc"    
#> [3] "apt-get install -y libicu-dev"
```
