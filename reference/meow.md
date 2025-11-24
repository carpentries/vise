# `cat()` for GitHub output variables

[`cat()`](https://rdrr.io/r/base/cat.html) for GitHub output variables

## Usage

``` r
meow(name, thing)
```

## Arguments

- thing:

  a vector that can be passed to
  [`cat()`](https://rdrr.io/r/base/cat.html)

- the:

  name of the output variable to write to

## Value

nothing. This is used to write output for GitHub

## Details

This is a way to print output for GitHub that requires you to pipe
output into the `GITHUB_OUTPUT` environment variable. This will write
single-line variables as `var=value` and multiline variables using a
random key according to this guidance from GitHub to avoid injection:
<https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions#multiline-strings>

## Examples

``` r
# NOTE: this function is not exported
tmp <- tempfile()
env <- Sys.getenv("GITHUB_OUTPUT", unset = "")
on.exit(Sys.setenv("GITHUB_OUTPUT" = env))
Sys.setenv("GITHUB_OUTPUT" = tmp)
vise <- asNamespace("vise")
vise$meow("single", "hello!")
vise$meow("multi", c("This information", "exists on", "multiple lines"))
writeLines(readLines(tmp))
#> single=hello!
#> multi<<EdLieexomb92Q9QeuR8H
#> This information
#> exists on
#> multiple lines
#> EdLieexomb92Q9QeuR8H
```
