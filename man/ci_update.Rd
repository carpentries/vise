% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/update.R
\name{ci_update}
\alias{ci_update}
\title{Update Packages in a {renv} lockfile in GitHub Actions}
\usage{
ci_update(profile = "lesson-requirements", update = "true", repos = NULL)
}
\arguments{
\item{profile}{the profile of the renv project}

\item{update}{a character vector of \code{'true'} (default) or \code{'false'}, which
indicates whether or not the existing packages should be updated.}

\item{repos}{the repositories to use in the search.}
}
\description{
With actively developed projects, it can be beneficial to auto-update
packages used in the project with a failsafe to roll back versions in case
there are breaking changes that need to be fixed. This is noramlly
accomplished via the function \code{\link[renv:update]{renv::update()}}, but that assumes that no new
packages have been introduced into your workflow. This function searches for
new packages, and updates existing packages.
}
