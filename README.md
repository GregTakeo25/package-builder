
# DEPRECATED

This repository is now deprecated. The files here were used for
building RPM packages of [rippled](https://github.com/ripple/rippled) versions
1.2 an earlier. For rippled 1.3+ release, the packaging files (including docker
definitions, cmake targets, etc.) are included in the rippled repository
itself.

# Rippled Package Builder

Docker image for building rippled rpms

The rpm-builder docker container builds a rippled rpm from the specified git branch and puts a tar.gz of rpms in a mounted directory.

Writes `md5sum`, `rippled_version`, and `rpm_file_name` variables to `build_vars` properties file in mounted directory.

## Dependencies

- docker

## Configuration

All configuration is performed via environment variables:

- GIT_BRANCH:  rippled branch to package (default: develop)
- GIT_COMMIT:  rippled commit to package (overrides GIT_BRANCH)
- GIT_REMOTE:  rippled remote repository (default: origin)
- RPM_RELEASE: rpm release number        (default: 1)
- RPM_PATCH:   rpm patch number          (default: null)

## Build

```
docker build -t rippled-rpm-builder rpm-builder/
```

## Run

```
docker run -e GIT_BRANCH=develop -v <path-to-out-dir>:/opt/rippled-rpm/out rippled-rpm-builder
```

## Test

```
./run_test.sh
```
