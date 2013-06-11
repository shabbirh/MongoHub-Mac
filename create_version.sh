#!/bin/sh
VERSION="2.5.9(103)"
git commit -m "software update $VERSION" .
git tag -a "$VERSION" -m "software update $VERSION"
git push --tags
