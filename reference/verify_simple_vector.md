# Verify that an input is a simple vector

In some GitHub actions, you can pass an arbitrary R vector in and we
will parse it. Unfortunately, this can lead to the insertion of
malicious code, so this function will thrown an error if the submitted R
expression is anything but a vector created with
[`c()`](https://rdrr.io/r/base/c.html),

## Usage

``` r
verify_simple_vector(inputs)
```

## Arguments

- inputs:

  an R expression

## Value

nothing. this is called for its side-effect. if `inputs` is not a simple
vector, an error will be thrown.

## Examples

``` r
# simple vectors work.
try(vise::verify_simple_vector(c(1, "a", c(TRUE, FALSE))))

# vectors using any other function fail, even if they are harmless
try(vise::verify_simple_vector(c(1, print("a"), c(TRUE, FALSE))))
#> Error in vise::verify_simple_vector(c(1, print("a"), c(TRUE, FALSE))) : 
#>   ::error::repository settings should be an R vector. No functions other than `c()` are allowed
```
