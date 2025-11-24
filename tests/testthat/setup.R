# tests/testthat/setup.R

# Set the pak/pkgcache user cache directory to a temporary location for testing
Sys.setenv(R_USER_CACHE_DIR = tempfile())

# Optional: Add an on.exit function to clean up the temporary cache directory
# This ensures that the directory is removed after the tests are finished running.
withr::defer(
  unlink(Sys.getenv("R_USER_CACHE_DIR"), recursive = TRUE),
  teardown_env()
)