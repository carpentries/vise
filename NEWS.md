# vise 0.0.0.9001

* `ci_update()` now sends output messages using GitHub's environment variable syntax
* `ci_update()` will now attempt to re-try failed installations due to missing 
  system requirements.
* new function `ci_new_pkg_sysreqs()` will take a list of packages and attempt
  to install their system dependencies.
- `lock2desc()` now can also take in a description object in place of `lockfile`
* First tracked version of {vise}
