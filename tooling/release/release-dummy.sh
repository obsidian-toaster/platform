#!/bin/bash

#
# Script using Forked Github repo & publish the artifacts to a local Maven Repo (Nexus, ...)
# Example : ./release-dummy.sh 1.0.0.Dummy 1.0.1-SNAPSHOT backend-generator-obsidian-dummy.172.28.128.4.xip.io obsidian-tester openshift-nexus::default::http://nexus-nexus.172.28.128.4.xip.io/content/repositories/snapshots/
#


: ${1:?"Must specify release version. Ex: 2.0.1.Final"}
: ${2:?"Must specify next development version. Ex: 2.0.2-SNAPSHOT"}
: ${3:?"Must specify backend url. Ex: http://generator-backend.myhost.io/forge"}
: ${4:?"Must specify github organization containing forked repo"}
: ${5:?"Could specify Alternate Maven Repo to publish. Ex: openshift-nexus::default::http://nexus-nexus.172.28.128.4.xip.io/content/repositories/snapshots/"}

REL=$1
DEV=$2
export FORGE_URL=$3
ORG=$4
MAVEN_REPO=$5

WORK_DIR=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`
echo "Working in temp directory $WORK_DIR"
cd $WORK_DIR

function mvnRelease {
  REPO=$1
  REPODIR=$2
  git clone $REPO $REPODIR
  cd $REPODIR
  #sed -i -e "s/obsidian-toaster-quickstarts\//$ORG\//g" pom.xml
  #sed -i -e "s/obsidian-toaster\//$ORG\//g" pom.xml
  echo "mvn release:prepare -Darguments=-Dobs.scm.git.connection=\"scm:git:git://github.com/$ORG/$REPODIR.git\" \
                      -Dobs.scm.dev.connection=\"scm:git:git@github.com:$ORG/$REPODIR.git\" \
                      -Dobs.scm.url=\"http://github.com/$ORG/$REPODIR\" \
                      -Dobs.scm.tag=\"HEAD\" \
                      -B -DaltDeploymentRepository=$MAVEN_REPO -DreleaseVersion=$REL -DdevelopmentVersion=$DEV -Dtag=$REL"
  mvn release:prepare -Darguments=-Dobs.scm.git.connection="scm:git:git://github.com/$ORG/$REPODIR.git" \
                      -Dobs.scm.dev.connection="scm:git:git@github.com:$ORG/$REPODIR.git" \
                      -Dobs.scm.url="http://github.com/$ORG/$REPODIR" \
                      -Dobs.scm.tag=HEAD \
                      -B -DaltDeploymentRepository=$MAVEN_REPO -DreleaseVersion=$REL -DdevelopmentVersion=$DEV -Dtag=$REL
  cd -
}

function mvnReleasePerform {
  REPO=$1
  REPODIR=$2
  git clone $REPO $REPODIR
  cd $REPODIR
  #sed -i -e "s/obsidian-toaster-quickstarts\//$ORG\//g" pom.xml
  #sed -i -e "s/obsidian-toaster\//$ORG\//g" pom.xml
  mvn release:prepare -Darguments=-Dobs.scm.connection="scm:git:git://github.com/$ORG/$REPO.git" \
                      -Dobs.developer.connection="scm:git:git@github.com:$ORG/$REPO.git" \
                      -Dobs.scm.url="http://github.com/$ORG/$REPODIR" \
                      -Dobs.scm.tag=HEAD
                      -D-DaltDeploymentRepository=$MAVEN_REPO \
                      -B -DreleaseVersion=$REL -DdevelopmentVersion=$DEV -Dtag=$REL
  mvn release:perform -Darguments=-Dobs.scm.connection="scm:git:git://github.com/$ORG/$REPO.git" \
                      -Dobs.developer.connection="scm:git:git@github.com:$ORG/$REPO.git" \
                      -Dobs.scm.url="http://github.com/$ORG/$REPODIR" \
                      -Dobs.scm.tag=HEAD \
                      -DaltDeploymentRepository=$MAVEN_REPO
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
mvnRelease https://github.com/$ORG/quick_rest_vertx.git quick_rest_vertx
mvnRelease https://github.com/$ORG/quick_rest_springboot-tomcat.git quick_rest_springboot-tomcat
mvnRelease https://github.com/$ORG/quick_secured_rest-springboot.git quick_secured_rest-springboot


#
# Step 2. : Release Platform. Archetypes should be previously generated and pushed
# Generate from the QuickStarts the Maven corresponding archetypes
# Generate a Maven POM file containing the different archetypes to be used
#
echo Press any key to release the Platform...
read junk
git clone https://github.com/$ORG/platform platform
cd platform/archetype-builder
mvn clean compile exec:java
cd ../archetypes
git commit -a -m "Generating archetypes to release $REL"
cd ..
mvn versions:set -DnewVersion=$REL
git commit -a -m "Releasing $REL"
git tag "$REL"
mvn clean deploy -DaltDeploymentRepository=$MAVEN_REPO
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
mvnReleasePerform https://github.com/$ORG/obsidian-addon.git obsidian-addon

#
# Step 4 : Release Backend (PROD is not required)
#
# CATALOG_URL : List of the Archetypes that we will use to genetate the code (zip file downloaded by the user)
#
echo Press any key to release the Backend...
read junk
mvnReleasePerform https://github.com/$ORG/generator-backend.git generator-backend

#
# Step 5 : Release Frontend (PROD is not required)
# This is HTML/javascript project
# It uses REST Api exposed by the backend to access the services
# FORGE_URL : REST endpoint
#
echo Press any key to release the Frontend...
read junk
git clone https://github.com/$ORG/generator-frontend.git
cd generator-frontend
npm install package-json-io
node -e "var pkg = require('package-json-io'); pkg.read(function(err, data) { data.version = '$REL'.replace(/(?:[^\.]*\.){3}/, function(x){return x.substring(0, x.length - 1) + '-'}); pkg.update(data, function(){}); })"
git commit -a -m "Released $REL of generator-frontend"
git clone https://github.com/$ORG/obsidian-toaster.github.io.git build
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
