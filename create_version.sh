#!/bin/sh

set -eu

usage() {
  echo "Usage: $(basename $0) VERSION"
}

VERSION="2.5.14"
VERSION="${1:?$(usage)}"

git commit -m "software update $VERSION" .
git push
git tag -a "$VERSION" -m "software update $VERSION"
git push --tags
