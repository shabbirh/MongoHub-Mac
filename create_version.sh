#!/bin/sh

set -eu

VERSION="$1"
if [ "$VERSION" = "" ] ; then
  echo "Usage: $(basename $0) VERSION"
  exit 1
fi

git commit -m "software update $VERSION" .
git push
git tag -a "$VERSION" -m "software update $VERSION"
git push --tags
