# Update Packages in a renv lockfile in GitHub Actions

With actively developed projects, it can be beneficial to auto-update
packages used in the project with a failsafe to roll back versions in
case there are breaking changes that need to be fixed. This is noramlly
accomplished via the function
[`renv::update()`](https://rstudio.github.io/renv/reference/update.html),
but that assumes that no new packages have been introduced into your
workflow. This function searches for new packages, and updates existing
packages.

## Usage

``` r
ci_update(
  profile = "lesson-requirements",
  update = "true",
  skip_restore = "false",
  repos = NULL
)
```

## Arguments

- profile:

  the profile of the renv project

- update:

  a character vector of `'true'` (default) or `'false'`, which indicates
  whether or not the existing packages should be updated.

- skip_restore:

  do not attempt to restore the renv.lock packages before hydration
  (this can be useful to update broken or very old packages, or when R
  updates and existing package versions cannot be restored)

- repos:

  the repositories to use in the search.
