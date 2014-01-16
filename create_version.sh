#!/bin/sh
VERSION="2.5.14"
VERSION="$1"
if [ "$VERSION" = "" ] ; then
  echo "Need the version as the parameter"
  exit 1
fi
git commit -m "software update $VERSION" .
git push
git tag -a "$VERSION" -m "software update $VERSION"
git push --tags
