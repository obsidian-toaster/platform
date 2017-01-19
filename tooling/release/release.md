# Release 

This document describes how to build Obsidian project (Front, Backend & QuickStarts)and deploy it in OpenShift. To support the building and deployment process, different shell script have been created.
They are described here after :

- release.sh : Build Obsidian and publish the maven artefacts within the JBoss Nexus Server. An account is required with the appropraite credentials to use it from your machine
- release-dummy.sh: Build Obsidian and publish the maven artefacts to a local Nexus server
- release-openshift.sh: Deploy a specific version of Obsidian into an OpenShift Server

The following projects are part of the build process :

- [Platform](https://github.com/obsidian-toaster/platform) : Tooling used to build, deploy Obisidan, convert QuickStart to Maven Archetypes and generate XML Maven Archetypes Catalog
- [Obsidian Addon](https://github.com/obsidian-toaster/obsidian-addon) : Forge Addons hadnling the requests to create an Obsidian Zip file using one of the QuickStarts or the starters (Vrt.x, WildFly Swarm, Spring Boot)
- [Generator Backend](https://github.com/obsidian-toaster//generator-backend) : WildFly Swarm server exposing the REST services called by the Front
- [Generator Front](https://github.com/obsidian-toaster/generator-front) : Obsidian Front end (Angularjs, Almighty JS & CSS)

## Prerequisites Infrastructure

To build the project on your machine, the following software are required:

- [Apache Maven 3.3.9](https://maven.apache.org/download.cgi)
- [JDK 8](http://www.oracle.com/technetwork/java/javase/downloads/jdk8-downloads-2133151.html)
- [OpenShift](https://github.com/obsidian-toaster/platform/blob/master/tooling/openshift/openshift-vm.md#deploy-locally-openshift-using-vagrant--virtualbox)  - optional
- [Sonatype Nexus Server](https://www.sonatype.com/oss-thank-you-tgz) - optional

## Nexus

To build the Obsidian project locally, we recommend to use a Nexus Server. If you haven't a server installed, you can create a nexus server
top of OpenShift using the following instructions: 

```
oc login https://172.28.128.4:8443 -u admin -p admin
oc new-project infra
oc create -f templates/ci/nexus2-ephemeral.json
oc process nexus-ephemeral | oc create -f -
oc start-build nexus
```

The login/password to be used to access as admin your nexus server is `admin/admin123`

Nexus works better with `anyuid`. To enable it (as admin):

```
oc adm policy add-scc-to-user anyuid -z nexus -n infra
```

Configure your maven settings.xml file to have a profile & server definition

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

# Front Generator

## OpenShift

To deploy this project on OpenShift, verify that an OpenShift instance is available or setup one locally
using minishift

```
minishift delete
minishift start --deploy-router=true --openshift-version=v1.3.1
oc login --username=admin --password=admin
eval $(minishift docker-env)
```

To create our Obsidian Front UI OpenShift application, we will deploy an OpenShift template which
contains the required objects; service, route, BuildConfig & Deployment config. The docker image
used is registry.access.redhat.com/rhscl/nginx-18-rhel7 which exposes a HTTP Server.

To install the template and create a new application, use these commands

```
oc new-project front
oc create -f templates/template_s2i.yml
oc process front-generator-s2i | oc create -f -
oc start-build front-generator
```

Remark: In order to change the address of the backend that you will use on OpenShift, change the `BACKEND_URL` value defined within the file src/assets/settings.json and commit the change.

You can now access the backend using its route

```
curl http://$(oc get routes | grep front-generator | awk '{print $2}')/index.html
```

Remarks:

* For every new commit about this project `front-generator` that you want to test after the initial installation of the template, launching a new build
  on OpenShift is just required `oc start-build front-generator`

* If for any reasons, you would like to redeploy a new template, then you should first delete the template and the corresponding objects

```
oc delete is/front-generator
oc delete bc/front-generator
oc delete dc/front-generator
oc delete svc/front-generator
oc delete route/front-generator
oc delete template/front-generator
oc create -f templates/template_s2i.yml
oc process front-generator-s2i | oc create -f -
oc start-build front-generator
```

# S2i Scripts

The S2I scripts, packaged within this project allow to override the scripts used within the S2I Build Image. They have been created
as the build image will only execute the `npm install` during the assemby phase and `npm start` during the run phase.

As our process requires 2 installations instructions, the scripts have been customized

They can be tested locally using the [s2i tool](https://github.com/openshift/source-to-image) and this command

```
s2i build . ryanj/centos7-s2i-nodejs:current my-nodejs -c
```

# Backend

To deploy the backend generator on OpenShift, run this command within the terminal

```
oc new-project backend
oc create -f templates/backend-template.yml
oc process backend-generator-s2i | oc create -f -
oc start-build generator-backend-s2i
```

Redeploy the application with:

```
mvn fabric8:deploy -Popenshift
```

You can verify now that the service replies

```
http $(minishift service generator-backend --url=true)/forge/version
curl $(minishift service generator-backend --url=true)/forge/version
```

