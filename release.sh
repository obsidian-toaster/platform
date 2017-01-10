#!/bin/bash

: ${1:?"Must specify release version. Ex: 2.0.1.Final"}
: ${2:?"Must specify next development version. Ex: 2.0.2-SNAPSHOT"}
: ${3:?"Must specify backend url. Ex: http://generator-backend.myhost.io/forge"}

REL=$1
DEV=$2
export FORGE_URL=$3

WORK_DIR=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`
echo "Working in temp directory $WORK_DIR"
cd $WORK_DIR

function mvnRelease {
  REPO=$1
  REPODIR=$2
  git clone $REPO
  cd $REPODIR
  mvn release:prepare -B -DreleaseVersion=$REL -DdevelopmentVersion=$DEV -Dtag=$REL -Dobsidian.forge.version=$REL
  mvn release:perform
  cd -
}
echo Press any key to release the Quickstarts...
read junk
# Release Quickstarts - TODO: no need to release:perform it
// TODO - Release the archetypes on Maven Central instead of JBoss Repository Maven Nexus
mvnRelease https://github.com/obsidian-toaster-quickstarts/quick_rest_vertx.git quick_rest_vertx
mvnRelease https://github.com/obsidian-toaster-quickstarts/quick_rest_springboot-tomcat.git quick_rest_springboot-tomcat
mvnRelease https://github.com/obsidian-toaster-quickstarts/quick_secured_rest-springboot.git quick_secured_rest-springboot

echo Press any key to release the Platform...
read junk

# Release Platform. Archetypes should be previously generated and pushed
// TODO - Step missing - Should be investigated by George Gastaldi
mvnRelease https://github.com/obsidian-toaster/platform platform

echo Press any key to release the Obsidian addon...
read junk

# Release Obsidian addon
mvnRelease https://github.com/obsidian-toaster/obsidian-addon.git obsidian-addon

echo Press any key to release the Backend...
read junk

# Release Backend
// TODO - replace value using sed (George Gastaldi)
mvnRelease https://github.com/obsidian-toaster/generator-backend.git generator-backend

echo Press any key to release the Frontend...
read junk

# Release Frontend
// TODO - use the release_front.sh script

# clean up
echo "Cleaning up temp directory $WORK_DIR"
rm -rf $WORK_DIR
