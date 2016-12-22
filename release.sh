#!/bin/bash

: ${1:?"Must specify release version. Ex: 2.0.1.Final"}
: ${2:?"Must specify next development version. Ex: 2.0.2-SNAPSHOT"}

REL=$1
DEV=$2

WORK_DIR=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`
echo "Working in temp directory $WORK_DIR"
cd $WORK_DIR

function mvnRelease {
  REPO=$1
  REPODIR=$2
  git clone $REPO
  cd $REPODIR
  mvn release:prepare release:perform -B -DreleaseVersion=$REL -DdevelopmentVersion=$DEV -Dobsidian.forge.version=$REL
  cd -
}

function mvnReleasePrepare {
  REPO=$1
  REPODIR=$2
  git clone $REPO
  cd $REPODIR
  mvn release:prepare release:clean -B -DreleaseVersion=$REL -DdevelopmentVersion=$DEV
  cd -
}

# Release Quickstarts - no need to release:perform it
mvnReleasePrepare https://github.com/obsidian-toaster-quickstarts/quick_rest_vertx.git quick_rest_vertx
mvnReleasePrepare https://github.com/obsidian-toaster-quickstarts/quick_rest_springboot-tomcat.git quick_rest_springboot-tomcat
mvnReleasePrepare https://github.com/obsidian-toaster-quickstarts/quick_secured_rest-springboot.git quick_secured_rest-springboot

# Release Obsidian addon
mvnRelease https://github.com/obsidian-toaster/obsidian-addon.git obsidian-addon

# Release Backend
mvnRelease https://github.com/obsidian-toaster/generator-backend.git generator-backend

# Release Frontend
git clone https://github.com/obsidian-toaster/generator-frontend.git
cd generator-frontend
npm install package-json-io
node -e "var pkg = require('package-json-io'); pkg.read(function(err, data) { data.version = '$REL'; pkg.update(data, function(){}); })"
git commit -m "released $REL of generator-frontend"
git tag "$REL"
git push origin --tags
npm publish .

# clean up
echo "Cleaning up temp directory $WORK_DIR"
rm -rf $WORK_DIR
