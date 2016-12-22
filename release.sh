#!/bin/bash

: ${1:?"Must specify release version. Ex: 2.0.1.Final"}
: ${2:?"Must specify next development version. Ex: 2.0.2-SNAPSHOT"}

VERSION=$1
DEV=$2

WORK_DIR=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`
echo "Working in temp directory $WORK_DIR"
cd $WORK_DIR

function mvnRelease {
  mvn release:prepare -B -DreleaseVersion=$VERSION -DdevelopmentVersion=$DEV -Dobsidian.forge.version=$VERSION
  mvn release:perform
}

function release {
  REPO=$1
  REPODIR=$2
  git clone $REPO
  cd $REPODIR
  mvnRelease
  cd -
}

# Release Quickstarts
release https://github.com/obsidian-toaster-quickstarts/quick_rest_vertx.git quick_rest_vertx
release https://github.com/obsidian-toaster-quickstarts/quick_rest_springboot-tomcat.git quick_rest_springboot-tomcat
release https://github.com/obsidian-toaster-quickstarts/quick_secured_rest-springboot.git quick_secured_rest-springboot

# Release Obsidian addon
release https://github.com/obsidian-toaster/obsidian-addon.git obsidian-addon

# Release Backend
release https://github.com/obsidian-toaster/generator-backend.git generator-backend

# Release Frontend
git clone https://github.com/obsidian-toaster/generator-frontend.git
cd generator-frontend

npm install package-json-io
node -e "var pkg = require('package-json-io'); pkg.read(function(err, data) { data.version = '$VERSION'; pkg.update(data, function(){}); })"
git commit -m "released $VERSION of generator-frontend"
git tag "$VERSION"
git push origin --tags
npm publish .

# clean up
echo "Cleaning up temp directory $WORK_DIR"
rm -rf $WORK_DIR
