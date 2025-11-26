# convert a lockfile to a description file

By default, this will take in a lockfile or a desc object and convert it
to an equivalent DESCRIPTION file for use with packages that check for
system dependencies.

## Usage

``` r
lock2desc(lockfile, desc = tempfile())
```

## Arguments

- lockfile:

  the path to the renv lockfile OR a
  [`desc::description()`](https://desc.r-lib.org/reference/description.html)
  object.

- desc:

  the path to the new description file

## Value

the path to the new description file

## Examples

``` r
lock <- system.file("renv.lock", package = "vise")
lock2desc(lock)
#> [1] "/tmp/Rtmpw973nS/file2540469a9104/DESCRIPTION"
```
