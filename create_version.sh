#!/bin/sh
VERSION="2.5.14"
VERSION="$1"
echo $VERSION
git commit -m "software update $VERSION" .
git push
git tag -a "$VERSION" -m "software update $VERSION"
git push --tags
