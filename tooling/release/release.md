# Release instructions

This document describes how to build Obsidian project (Front, Backend & QuickStarts)and deploy it in OpenShift. To support the building and deployment process, different shell script have been created.
They are described here after :

- release.sh : Build Obsidian and publish the maven artefacts within the JBoss Nexus Server. An account is required with the appropraite credentials to use it from your machine
- release-dummy.sh: Build Obsidian and publish the maven artefacts to a local Nexus server
- release-openshift.sh: Deploy a specific version of Obsidian into an OpenShift Server

The following projects are part of the build process :

- [Platform](https://github.com/obsidian-toaster/platform) : Tooling used to build, deploy Obisidan, convert QuickStart to Maven Archetypes and generate XML Maven Archetypes Catalog
- [Obsidian Addon](https://github.com/obsidian-toaster/obsidian-addon) : Forge Addons handling the requests to create an Obsidian Zip file using one of the QuickStarts or the starters (Vrt.x, WildFly Swarm, Spring Boot)
- [Generator Backend](https://github.com/obsidian-toaster//generator-backend) : WildFly Swarm server exposing the REST services called by the Front
- [Generator Front](https://github.com/obsidian-toaster/generator-front) : Obsidian Front end (Angularjs, Almighty JS & CSS)

## Prerequisites Infrastructure

To build the project on your machine, the following software are required:

- [Apache Maven 3.3.9](https://maven.apache.org/download.cgi)
- [JDK 8](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)
- [OpenShift](https://github.com/obsidian-toaster/platform/blob/master/tooling/openshift/openshift-vm.md#deploy-locally-openshift-using-vagrant--virtualbox)  - optional
- [Sonatype Nexus Server](https://www.sonatype.com/oss-thank-you-tgz) - optional

Git clone this project `git clone https://github.com/obsidian-toaster/platform.git platform && cd platform` and move to release folder `cd tooling/release`

## Nexus on OpenShift

To build the Obsidian project locally, we recommend to use a Nexus Server. If you haven't a server installed, you can create a nexus server
top of OpenShift using the following instructions:

```
oc login https://$HOSTNAME_OPENSHIT_SERVER:8443 -u admin -p admin
oc new-project infra
oc create -f templates/ci/nexus2-ephemeral.json
oc process nexus-ephemeral | oc create -f -
oc start-build nexus
```

Remarks :
- The login/password to be used to access as admin your nexus server is `admin/admin123`
- Change the HOSTNAME_OPENSHIT_SERVER var with the name of the Openshift Server to be tested
- You can use the CI/CD server for that purpose `172.16.50.40`if you have access through the VPN to it. Contact George Gastaldi for more 

Nexus works better with `anyuid`. To enable it (as admin):

```
oc adm policy add-scc-to-user anyuid -z nexus -n infra
```

Next, Configure your maven settings.xml file to have a profile & server definition. The profile should be active.

```
<?xml version="1.0" encoding="UTF-8"?>
<settings xsi:schemaLocation="http://maven.apache.org/SETTINGS/1.1.0 http://maven.apache.org/xsd/settings-1.1.0.xsd" xmlns="http://maven.apache.org/SETTINGS/1.1.0"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <localRepository>/Users/chmoulli/.m2/repository</localRepository>
  <servers>
    <!-- USE THIS ID TILL WE CAN CHANGE IT WITHIN THE JBOSS PARENT POM -->
    <server>
      <id>jboss-releases-repository</id>
      <username>admin</username>
      <password>admin123</password>
    </server>
  	<server>
      <id>openshift-nexus</id>
      <username>admin</username>
      <password>admin123</password>
    </server>
    ...

  <profile>
  <id>openshift-nexus</id>
  <properties>
    <altReleaseDeploymentRepository>openshift-nexus::default::http://nexus-infra.172.28.128.4.xip.io/content/repositories/releases</altReleaseDeploymentRepository>
    <altSnapshotDeploymentRepository>openshift-nexus::default::http://nexus-infra.172.28.128.4.xip.io/content/repositories/snapshots</altSnapshotDeploymentRepository>
  </properties>
</profile>
```

## Snapshot release

### Build & publish maven snapshot artifacts

In order to test latest code of Obsidian Quickstarts, Generator, Forge Addon, ... snapshots maven artifacts could be generated and published on a Nexus Maven Server using the following script `deploy-snapshots.sh`.
It accepts a parameter which is the address of the Nexus server where you target to deploy/publish the artifacts

Usage:

1) Example to deploy on a local Nexus Server
```
./deploy-snapshots.sh nexus-infra.172.28.128.4.xip.io/content/repositories/snapshots
```

2) When you omit the parameter, then the artifacts will be published on the JBoss nexus server
```
./deploy-snapshots.sh
```

Remark : For local deployment, verify that you have added within your maven `settings.xml` file a server id for
 `<id>jboss-releases-repository</id>` and `<id>jboss-snapshots-repository</id>` containing the username/password
 
The script will execute the following tasks :
 
A) Step 1

- Generate from the QuickStarts the Maven corresponding archetypes
- Generate a Maven XML file containing the maven archetypes generated
- Publish the maven archetypes and XML Archetypes Catalog

B) Step 2

- Build and publish Obsidian Forge addon

C) Step 3

- Build and publish the Obsidian Backend

D) Step 4

- Using npm, build the obsidian front project
- Generate the static content and publish it on `https://github.com/obsidian-toaster/obsidian-toaster.github.io` within the master branch

### Deploy on OpenShift

The `deploy-snapshots-openshift.sh` script simplifies the deployment of the Front/Backend application on OpenShift as it will use the front-snapshot.yml and backend-snapshot.yml template files
to create the OpenShift Templates to be used in order to deploy the Front & Backend Pod in an OpenShift project/namespace.

- The Front S2I build process will git clone the repo `https://github.com/obsidian-toaster/obsidian-toaster.github.io`, replace the `backend_url` value within the `settings.json` file and create a pod from the S2I Build image - rhscl/nginx-18-rhel7
- The Backend S2I build process will use as binary file the `generator-swarm` as defined [here](https://github.com/obsidian-toaster/generator-backend/blob/master/.s2i/bin/assemble#L43) during the Java S2I build, replace the variables as defined hereafter and run a Java Pod.

During the execution of the script, different variables will be replaced within the file as summarized hereafter:

**Front**

- The `VERSION` is replaced with the value passed as parameter -v and corresponds to the snapshot version `e.g. 1.0.0-SNAPSHOT`. This version will be used to name the yml file, to tag the label of the pod
- The `GENERATOR_URL` is replaced by the value passed as parameter with -b and will be used to define an ENV variable `backend_url` used during S2I build to specify the address of the backend used by the front.
  This `ENV` var will be used to replace the value defined within file `settings.json` according to the assemble file `front-generator` [project](https://github.com/obsidian-toaster/obsidian-toaster.github.io/blob/master/.s2i/bin/assemble#L8). 
- The `ORG` variable (which is not defined as bash parameter) could be changed to change the location of the github organisation containg the projects to be processed

**Backend**

- The `VERSION` is replaced with the value passed as parameter -v and corresponds to the snapshot version `e.g. 1.0.0-SNAPSHOT`. This version will be used to name the yml file, to tag the label of the pod
- The `ORG` variable (which is not defined as bash parameter) could be changed to change the location of the github organisation containg the projects to be processed
- The `MANSERVER` variable is replaced using the bash parameter -n. It points to the nexus jboss server (but could also point to your own Nexus server).
- The `MAVENMIRRORURL` variable is derived from the path of the MAVENSERVER and will point to the address `$mavenserver/content/repositories/snapshots`
- The `ARCHETYPECATALOG` variable is replaced using the bash parameter -c. It will allow to set an ENV var used by the WildFly Swarm / Forge Addon when the POD will be created from the
  DeploymentConfig to fetch the XML Maven Archetypes catalog to be used.

1) Local deployment

The script can be used to deploy the Front/Backend using a local instance of OpenShift where you pass the username and password as parameters. When the script will be executed
the templates yaml files will be created within the `templates` directory, a project `obsidian-snapshot` created and the template uploaded.
From this template, the different objects will be created as BuildConfig, Service, Route, DeploymentConfig and the front / backend s2i build started.

```
./deploy-snapshots-openshift.sh -a 172.28.128.4 -u admin -p admin \
                                -v 1.0.0-SNAPSHOT \
                                -b http://backend-generator-obsidian-snapshot.172.28.128.4.xip.io/ \
                                -c 'https://repository.jboss.org/nexus/service/local/artifact/maven/redirect?r=snapshots\&g=org.obsidiantoaster\&a=archetypes-catalog\&v=1.0.0-SNAPSHOT\&e=xml\&c=archetype-catalog' \
                                -n http://repository.jboss.org/nexus
```

2) OpenShift Online

Alternatively, we can also deploy the project using an Openshift Online instance where the username/password is replaced by the user token.

```
./deploy-snapshots-openshift.sh -a api.engint.openshift.com -t xxxxxxxxx \
                               -v 1.0.0-SNAPSHOT \
                               -b http://backend-generator-obsidian-snapshot.e8ca.engint.openshiftapps.com/ \
                               -c 'https://repository.jboss.org/nexus/service/local/artifact/maven/redirect?r=snapshots\&g=org.obsidiantoaster\&a=archetypes-catalog\&v=1.0.0-SNAPSHOT\&e=xml\&c=archetype-catalog' \
                               -n http://repository.jboss.org/nexus

```

Remark : If the namespace obsidian-snapshot already exists, delete the objects using this `oc delete all --all` command.

## Dummy Release

In order to validate locally without the need to have the artifacts published on a snapshot maven server, you can build the Obsidian project and deploy the Front/backend within an Openshift Server.
That will help you to play with the technology, to make a demo but also to validate that all the pieces are in place in order to do the official release of the Obsidian Project.
During the dummy release process, the following steps will take place

1) Fork the different projects under a "dummy" github organization

```
./fork_repo.sh [dummy github org] [true/false - to delete or not the forked github repos]
```

2) Create a temporary directory & move to it

```
WORK_DIR=`mktemp -d 2>/dev/null || mktemp -d -t 'mytmpdir'`
echo "Working in temp directory $WORK_DIR"
cd $WORK_DIR
```

3) Git clone the quickstarts & release them

```
tagAndBump https://github.com/$ORG/rest_vertx.git rest_vertx
tagAndBump https://github.com/$ORG/rest_springboot-tomcat.git rest_springboot-tomcat
tagAndBump https://github.com/$ORG/secured_rest-springboot.git secured_rest-springboot
...
```

The tagAndBump function will git clone the project within the temporary folder, change the version to the release specified, 
tag the release in github using your forked repo and bump the version to the snapshot version specified.

4) Git clone the Platform project & generate the Maven Archetypes

```
git clone https://github.com/$ORG/platform platform
cd platform/archetype-builder
mvn clean compile exec:java -Dgithub.organisation=$ORG
cd ../archetypes
git commit -a -m "Generating archetypes to release $REL"
```

5) Release platform project

During this step, the project will be released like the QuickStarts, Maven Archetypes & Maven Archetypes Catalog
and the artifacts pushed to the Nexus Server

```
cd ..
mvn versions:set -DnewVersion=$REL
git commit -a -m "Releasing $REL"
git tag "$REL"
mvn clean deploy -DserverId=$MAVEN_REPO_ID -Djboss.releases.repo.id=$MAVEN_REPO_ID -Djboss.releases.repo.url=http://$MAVEN_REPO
git push origin --tags
mvn versions:set -DnewVersion=$DEV
git commit -a -m "Preparing for next version $DEV"
git push origin master
cd ..
```

6) Release the Obsidian Forge Addon project

```
mvnReleasePerform https://github.com/$ORG/obsidian-addon.git obsidian-addon
```

The mvnReleasePerform function executes the maven `release:prepare release:perform` goals.
It includes new parameters which are required to by pass the staging step executed by default by the nexus-maven-plugin to use
the nexus server defined within the `distributionManagement` xml tag of the parent project which is jboss.

```
-Darguments="-DserverId=$MAVEN_REPO_ID  # Not yet used
-Djboss.releases.repo.id=$MAVEN_REPO_ID # Server ID as defined within the settings.xml file
-Djboss.releases.repo.url=http://$MAVEN_REPO" # Address of the Nexus Server to push the artefacts
```

7) Release the backend project

```
mvnReleasePerform https://github.com/$ORG/generator-backend.git generator-backend
```

8) Generate the static content of front & release it

```
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
```

9) Clean the temporary folder

```
echo "Cleaning up temp directory $WORK_DIR"
rm -rf $WORK_DIR
```

10) Deploy the project in OpenShift

The Obsidian Front & the backend will be deployed as a Pod & a route created to access the server.

```
# Create project
oc new-project obsidian-dummy
sleep 5

# Deploy the backend
echo "Deploy the backend ..."
oc create -f ./templates/backend-dummy.yml
oc process backend-generator-s2i | oc create -f -
oc start-build backend-generator-s2i

# Deploy the Front
echo "Deploy the frontend ..."
oc create -f templates/front-dummy.yml
oc process front-generator-s2i | oc create -f -
oc start-build front-generator-s2i
```

The backend-dummy.yml and front-dummy.yml files are populated from the backend.yml and front.yml files where sed substitutions will be done to specify the following values:

- Version

We will add the version within the openshift yaml file to specify it as Kubernetes Label or to tell to S2I build which tag/branch should be git cloned

```
sed -e "s/VERSION/$REL/g"
```
- Github Org

To git clone the forked project, we will replace the parameter with the dummy github org passed as parameter

```
sed -e "s/ORG\//$githuborg\//g"
```

- Nexus Server

To tell to the Obsidian Backend where it can download the Maven Archetypes or Quickstart to be used when a zip file will be populated, then
we will add a MAVEN_MIRROR_URL address which is used by the Java S2I docker image during the S2I build to configure the settings.xml file

```
sed  -e "s|NEXUSSERVER|$nexusserver|g"
```

- Archetype Catalog

The archetype catalog parameter is used by the Obsidian Addon project in order to load the catalog of the XML Maven Archetypes catalog

```
sed -e "s|ARCHETYPECATALOG|$archetypecatalog|g"
```

- Backend URL

This parameter is used to configure the `setti,ngs.json` file during the S2I buyld process and is used by the front to access the backend server

```
sed -e "s|GENERATOR_URL|$backendurl|g"
```

### All in one

To perform the steps described before, you will use 2 shell scripts `fork_repo.sh` and `release-dummy.sh` and pass the parameters described hereafter
.

Example of scenario

```
#
# Fork the Github project within your dummy github org
# The script will ask you about your github username and password
# First parameter : github org where projects will be created
# 2nd parameter  : boolean value to delete the forked repositories
#
./fork_repo.sh obsidian-tester true

#
# Execute steps 2) to 9) using ./release-dummy script
# Version of the release
# Next project version
# Github Org containing the projects to be cloned
# Nexus Server running locally
# ServerID as defined within your settings.xml file and containing the credentials
#
./release-dummy.sh 1.0.0.Dummy 1.0.1-SNAPSHOT \
                   obsidian-tester \
                   nexus-infra.172.28.128.4.xip.io/content/repositories/releases \
                   openshift-nexus

./release-openshift.sh -a 172.28.128.4:8443 -u admin -p admin \
                       -v 1.0.0.Dummy \
                       -b http://backend-generator-obsidian-dummy.172.28.128.4.xip.io/ \
                       -o obsidian-tester \
                       -c http://nexus-infra.172.28.128.4.xip.io/content/repositories/releases/org/obsidiantoaster/archetypes-catalog/1.0.0.Dummy/archetypes-catalog-1.0.0.Dummy-archetype-catalog.xml \
                       -n http://nexus-infra.172.28.128.4.xip.io/content/repositories/releases
```

Access your front server at this address : http://front-generator-obsidian-dummy.172.28.128.4.xip.io & enjoy to play with Obsidian !

## Releasing

When a new release of Obsidian is ready to be tagged within the Github repo, artifacts published within the JBoss Nexus Server, then you will use the `./release.sh` script which is equivalent to the previous script except
that it will only require 3 parameters; `release version`, `next development version` and `backend url`.

The `release version` will be used to tag the github repos and to change the version of the pom.xml file
The `next development version` corresponds to the version number to be changed within the different pom.xml file

```
./release-dummy.sh 1.0.0.Alpha2 1.0.1-SNAPSHOT http://generator-backend.myhost.io/forge
```

