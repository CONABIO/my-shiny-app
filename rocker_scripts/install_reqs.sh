#!/bin/bash

set -e

## build ARGs
NCPUS=${NCPUS:--1}

# ---------------------------------------------------------------------------
# Posit Public Package Manager
#
# Two URLs are used:
#   PPPM_BINARY  – binary R packages for Ubuntu 24.04 (Noble).
#                  rocker/shiny:4.4+ is based on Ubuntu 24.04; change the
#                  distro slug here if you switch base images
#                  (e.g. "jammy" for Ubuntu 22.04).
#   PPPM_API     – sysreqs endpoint: returns the exact apt-get commands
#                  needed for any set of R packages, so the system-library
#                  list no longer needs to be maintained by hand.
# ---------------------------------------------------------------------------
PPPM_BINARY="https://packagemanager.posit.co/cran/__linux__/noble/latest"
PPPM_API="https://packagemanager.posit.co/__api__/repos/cran/sysreqs"
DISTRO="ubuntu"
RELEASE="24.04"
LOCKFILE="/renv.lock"

apt-get update
apt-get install -y --no-install-recommends \
    curl \
    make

R -q -e "
  options(
    repos = c(PPPM = '${PPPM_BINARY}'),
    HTTPUserAgent = sprintf(
      'R/%s R (%s)',
      getRversion(),
      paste(getRversion(), R.version['platform'], R.version['arch'], R.version['os'])
    )
  )
  install.packages(c('pak', 'renv'))
"

R -q -e "
  pak::pak_install_extra()
  pkgs <- names(renv::lockfile_read('${LOCKFILE}')\$Packages)
  message('Querying PPPM sysreqs API for ', length(pkgs), ' packages ...')
  pak::pkg_sysreqs(pkgs, sysreqs_platform='ubuntu')
"


R -q -e "
  options(
    repos = c(PPPM = '${PPPM_BINARY}'),
    HTTPUserAgent = sprintf(
      'R/%s R (%s)',
      getRversion(),
      paste(getRversion(), R.version['platform'], R.version['arch'], R.version['os'])
    )
  )
  renv::restore(
    lockfile = '${LOCKFILE}',
    library  = .libPaths()[1],
    prompt   = FALSE
  )
"

# ---------------------------------------------------------------------------
# Clean up
# ---------------------------------------------------------------------------
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/downloaded_packages

## Strip binary installed libraries from RSPM
## https://github.com/rocker-org/rocker-versioned2/issues/340
strip /usr/local/lib/R/site-library/*/libs/*.so 2>/dev/null || true

echo -e "\nAll system and R dependencies installed from renv.lock — done!"