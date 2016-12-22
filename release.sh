#!/bin/bash

: ${1:?"Must specify release version. Ex: 2.0.1.Final"}
: ${2:?"Must specify next development version. Ex: 2.0.2-SNAPSHOT"}
: ${3:?"Must specify backend url. Ex: http://generator-backend.myhost.io"}

REL=$1
DEV=$2
FORGE_URL=$3

WORK_DIR=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`
echo "Working in temp directory $WORK_DIR"
cd $WORK_DIR

function mvnRelease {
  REPO=$1
  REPODIR=$2
  git clone $REPO
  cd $REPODIR
  mvn release:prepare release:perform -B -DreleaseVersion=$REL -DdevelopmentVersion=$DEV -Dtag=$REL -Dobsidian.forge.version=$REL
  cd -
}

# Release Quickstarts - TODO: no need to release:perform it
mvnRelease https://github.com/obsidian-toaster-quickstarts/quick_rest_vertx.git quick_rest_vertx
mvnRelease https://github.com/obsidian-toaster-quickstarts/quick_rest_springboot-tomcat.git quick_rest_springboot-tomcat
mvnRelease https://github.com/obsidian-toaster-quickstarts/quick_secured_rest-springboot.git quick_secured_rest-springboot

# Release Platform
git clone https://github.com/obsidian-toaster/platform
cd platform/archetype-builder
mvn clean compile exec:java
cd ..
mvn release:prepare release:perform -B -DreleaseVersion=$REL -DdevelopmentVersion=$DEV -Dtag=$REL
cd $WORK_DIR

# Release Obsidian addon
mvnRelease https://github.com/obsidian-toaster/obsidian-addon.git obsidian-addon

# Release Backend
mvnRelease https://github.com/obsidian-toaster/generator-backend.git generator-backend

# Release Frontend
git clone https://github.com/obsidian-toaster/generator-frontend.git
cd generator-frontend
npm install package-json-io
node -e "var pkg = require('package-json-io'); pkg.read(function(err, data) { data.version = '$REL'; pkg.update(data, function(){}); })"
git commit -a -m "Released $REL of generator-frontend"
git clone https://github.com/obsidian-toaster/obsidian-toaster.github.io.git build
cd build
git branch "$REL"
git checkout "$REL"
rm -rf *
cd -
npm install
npm run build:prod
cp -r dist/* build
cd build
git commit -a -m "Released $REL of generator-frontend"
git push origin "$REL"
cd -

git tag "$REL"
git push origin --tags
npm publish .

# clean up
echo "Cleaning up temp directory $WORK_DIR"
rm -rf $WORK_DIR
