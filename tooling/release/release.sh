#!/bin/bash

: ${1:?"Must specify release version. Ex: 2.0.1.Final"}
: ${2:?"Must specify next development version. Ex: 2.0.2-SNAPSHOT"}
: ${3:?"Must specify backend url. Ex: http://generator-backend.myhost.io"}

REL=$1
DEV=$2
export BACKEND_URL=$3
CURRENT=$(pwd)

WORK_DIR=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`
echo "Working in temp directory $WORK_DIR"
cd $WORK_DIR

function tagAndBump {
  REPO=$1
  REPODIR=$2
  git clone $REPO $REPODIR
  cd $REPODIR
  mvn versions:set -DnewVersion=$REL
  git commit -a -m "Releasing $REL"
  git tag "$REL"
  mvn versions:set -DnewVersion=$DEV
  git commit -a -m "Preparing for next version $DEV"
  git push --tags && git push origin master
  cd -
}

function mvnReleasePerform {
  REPO=$1
  REPODIR=$2
  git clone $REPO $REPODIR
  cd $REPODIR
  mvn release:prepare -B -DreleaseVersion=$REL -DdevelopmentVersion=$DEV -Dtag=$REL
  mvn release:perform
  cd -
}


#
# Third party Dependencies should be productized first
# Vert.x, WildFly Swarm, Apache Tomcat, Fabric8 Maven Plugin, Vert.x Forge Addon & Vert.x Fabric8 Maven plugin
#

#
# Step 1. : Release QuickStarts - no need to release:perform it
#
echo Press any key to release the Quickstarts...
read junk
JSONFILE=$CURRENT/quickstarts.json
START=0
END=$(jq '. | length' $JSONFILE)
for ((c=$START;c<=$END-1; c++ ))
do
  name=$(jq -r '.['$c'].name' $JSONFILE)
  tagAndBump https://github.com/$ORG/$name.git $name
done

#
# Step 2. : Release Platform. Archetypes should be previously generated and pushed
# Generate from the QuickStarts the Maven corresponding archetypes
# Generate a Maven POM file containing the different archetypes to be used
#
echo Press any key to release the Platform...
read junk
git clone https://github.com/obsidian-toaster/platform platform
cd platform/archetype-builder
mvn clean compile exec:java
cd ../archetypes
git commit -a -m "Generating archetypes to release $REL"
cd ..
mvn versions:set -DnewVersion=$REL
git commit -a -m "Releasing $REL"
git push origin master
git tag "$REL"
mvn clean deploy
git push origin --tags
mvn versions:set -DnewVersion=$DEV
git commit -a -m "Preparing for next version $DEV"
git push origin master
cd ..


#
# Step 3 : Release Obsidian Forge addon
#
echo Press any key to release the Obsidian addon...
read junk
mvnReleasePerform https://github.com/obsidian-toaster/obsidian-addon.git obsidian-addon


#
# Step 4 : Release Backend (PROD is not required)
#
# CATALOG_URL : List of the Archetypes that we will use to genetate the code (zip file downloaded by the user)
#
echo Press any key to release the Backend...
read junk
mvnReleasePerform https://github.com/obsidian-toaster/generator-backend.git generator-backend

#
# Step 5 : Release Frontend (PROD is not required)
# This is HTML/javascript project
# It uses REST Api exposed by the backend to access the services
# BACKEND_URL : REST endpoint
#
echo Press any key to release the Frontend...
read junk
git clone https://github.com/obsidian-toaster/generator-frontend.git
cd generator-frontend
npm install package-json-io
node -e "var pkg = require('package-json-io'); pkg.read(function(err, data) { data.version = '$REL'.replace(/(?:[^\.]*\.){3}/, function(x){return x.substring(0, x.length - 1) + '-'}); pkg.update(data, function(){}); })"
git commit -a -m "Released $REL of generator-frontend"
git clone https://github.com/obsidian-toaster/obsidian-toaster.github.io.git build
cd build
git checkout -b "$REL"
rm -rf *
cd -
npm install
npm run build:prod
cp -r dist/* build
cd build
git add .
git commit -a -m "Released $REL of generator-frontend"
git push origin "$REL"
cd -
git tag "$REL"
git push origin --tags

# clean up
echo "Cleaning up temp directory $WORK_DIR"
rm -rf $WORK_DIR
