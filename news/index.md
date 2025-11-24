# Changelog

## vise 0.0.1.9000

- [`ci_update()`](https://zkamvar.github.io/vise/reference/ci_update.md)
  now accepts a skip_restore option to force lockfile updating
  1.  

## vise 0.0.0.9004

- [`ci_update()`](https://zkamvar.github.io/vise/reference/ci_update.md)
  now uses `renv::snapshot(force = TRUE)` to avoid spurious pre-flight
  validation errors ([@zkamvar](https://github.com/zkamvar),
  [\#7](https://github.com/zkamvar/vise/issues/7))

## vise 0.0.0.9003

- This package now requires {renv} version 0.17.3 or greater.
- The shim for renv 0.17.1 has been replaced by a capture output command
  on the initial update check. Because {renv} \>= 0.17.1 now prints to
  stdout instead of stderr, it simplifies the code a bit.

## vise 0.0.0.9002

- a random delimiter is set for setting github output parameters
- a shim for renv 0.17.1 has been set to fix broken package update
  reports.

## vise 0.0.0.9001

- [`ci_update()`](https://zkamvar.github.io/vise/reference/ci_update.md)
  now sends output messages using GitHub’s environment variable syntax
- [`ci_update()`](https://zkamvar.github.io/vise/reference/ci_update.md)
  will now attempt to re-try failed installations due to missing system
  requirements.
- new function `ci_new_pkg_sysreqs()` will take a list of packages and
  attempt to install their system dependencies.
- [`lock2desc()`](https://zkamvar.github.io/vise/reference/lock2desc.md)
  now can also take in a description object in place of `lockfile`
- First tracked version of {vise}
