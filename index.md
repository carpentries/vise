# Vise

> A vise or vice is a mechanical apparatus used to secure an object to
> allow work to be performed on it.
>
> <https://en.wikipedia.org/wiki/Vise>

The {vise} package is a thin wrapper around {renv}, {desc}, and {pak}
that is designed to manage and update renv lockfiles in a project. This
explicitly works with The Carpentries lessons, but could be extended for
other use.

## Features

- [`ci_new_pkgs_sysreqs()`](https://zkamvar.github.io/vise/reference/ci_new_pkgs_sysreqs.md)
  create a description file on the fly from a set of package names,
  which are then passed to
  [`ci_sysreqs()`](https://zkamvar.github.io/vise/reference/ci_sysreqs.md).
- [`ci_sysreqs()`](https://zkamvar.github.io/vise/reference/ci_sysreqs.md)
  gather and install system requirements from a {renv} lockfile that
  de-duplicates the system calls and uses a single command.
- [`ci_update()`](https://zkamvar.github.io/vise/reference/ci_update.md)
  updates a lockfile in two ways: 1. scans project for new packages
  and 2. updates existing packages to their latest versions on cran.
  This is useful for creating pull requests with the changed lockfile to
  trigger previews with the new package versions.
- [`lock2desc()`](https://zkamvar.github.io/vise/reference/lock2desc.md)
  convert a lockfile to a DESCRIPTION file
- [`verify_simple_vector()`](https://zkamvar.github.io/vise/reference/verify_simple_vector.md)
  verifies that an input vector is actually a simple vector and not
  malicious code.

## Goals

This was originally intended to be the package that encompassed the
{renv} components from {sandpaper} so that it could be further exploited
for non-Carpentries uses. Time constraints have delayed that vision.

Instead, this is a lightweight package for use in [The Carpentries
GitHub Actions](https://github.com/carpentries/actions) in order to
provision and update packages so that the infrastructure does not need
to install the entire {sandpaper} suite to provision new packages.
