#!/bin/bash

#
# Script responsible to build & publish the snapshots
# Example :
# ./release-snapshots.sh 1.0.0-SNAPSHOT nexus-infra.172.28.128.4.xip.io/content/repositories/releases openshift-nexus
#

: ${1:?"Must specify snapshot version. Ex: 1.0.0-SNAPSHOT"}
: ${2:?"Must specify Alternate Maven Repo to publish. Ex: nexus-infra.172.28.128.4.xip.io/content/repositories/snapshots"}
: ${3:?"Must specify the Maven Server Id. Ex: openshift-nexus"}

DEV=$1
ORG="obsidian-toaster-quickstarts"
MAVEN_REPO=$2
MAVEN_REPO_ID=$3

CURRENT=$(pwd)

WORK_DIR=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`
echo "Working in temp directory $WORK_DIR"
cd $WORK_DIR

function mvnReleasePerform {
  REPO=$1
  REPODIR=$2
  git clone $REPO $REPODIR
  cd $REPODIR
  mvn clean deploy -DserverId=$MAVEN_REPO_ID -Djboss.releases.repo.url=http://$MAVEN_REPO -DskipStaging=true
  cd -
}

#
# Step 1. : Release Platform. Archetypes should be previously generated and pushed
# Generate from the QuickStarts the Maven corresponding archetypes
# Generate a Maven POM file containing the different archetypes to be used
#
echo Press any key to release the Platform...
read junk
git clone https://github.com/obsidian-toaster/platform platform
cd platform/archetype-builder
mvn clean compile exec:java -Dgithub.organisation=$ORG

cd ..
mvn clean deploy -DserverId=$MAVEN_REPO_ID -Djboss.releases.repo.url=http://$MAVEN_REPO -DskipStaging=true

cd ..


#
# Step 2. : Release Obsidian Forge addon
#
echo Press any key to release the Obsidian addon...
read junk
mvnReleasePerform https://github.com/obsidian-toaster/obsidian-addon.git obsidian-addon

#
# Step 3. : Release Backend (PROD is not required)
#
# CATALOG_URL : List of the Archetypes that we will use to genetate the code (zip file downloaded by the user)
#
echo Press any key to release the Backend...
read junk
mvnReleasePerform https://github.com/obsidian-toaster/generator-backend.git generator-backend

#
# Step 4. : Release Frontend (PROD is not required)
# This is HTML/javascript project
# It uses REST Api exposed by the backend to access the services
# FORGE_URL : REST endpoint
#
echo Press any key to release the Frontend...
read junk
git clone https://github.com/obsidian-toaster/generator-frontend.git
cd generator-frontend
npm install package-json-io
#node -e "var pkg = require('package-json-io'); pkg.read(function(err, data) { data.version = '$REL'.replace(/(?:[^\.]*\.){3}/, function(x){return x.substring(0, x.length - 1) + '-'}); pkg.update(data, function(){}); })"

git clone https://github.com/obsidian-toaster/obsidian-toaster.github.io.git build
cd build
git checkout -b "$DEV"
rm -rf *
cd -
npm install
npm run build:prod
cp -r dist/* build
cd build
git add .
git commit -a -m "Released $DEV of generator-frontend"
git push origin "$DEV"
cd -
#git tag "$REL"
#git push origin --tags

# clean up
echo "Cleaning up temp directory $WORK_DIR"
rm -rf $WORK_DIR