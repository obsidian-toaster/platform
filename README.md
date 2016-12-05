# Platform
[![Build Status](https://travis-ci.org/obsidian-toaster/platform.svg?branch=master)](https://travis-ci.org/obsidian-toaster/platform)

Tools used to build Obsidian (quickstart -> archetype, ...)

Fabric8 Project : https://github.com/fabric8io/ipaas-quickstarts/blob/master/ReadMe.md

## Generate the archetypes

* To build the archetypes, run this command within the project `archetype-builder` and the corresponding archetypes will be generated under the `archetypes` folder from the quickstarts

```
mvn clean compile exec:java
```

* To publish the catalog, move to the root of the project and execute this command `mvn clean install`, the catalog will be published and is generated under the project `archetypes-catalog/target/classes/archetype-catalog.xml`

* To deploy the quickstarts to the JBoss Nexus Repository, after performing the steps beforementioned, `cd archetypes/` and execute `mvn deploy` (you must have deploy privileges to Nexus, so make sure your settings.xml is properly configured as below)
````xml 
<servers>
  <server>
    <id>jboss-snapshots-repository</id>
    <username>my-nexus-username</username>
    <password>my-nexus-password</password>
  </server>
</servers>
````

## Tooling

The purpose of the Tooling project is to host reusable bash scripts that we need/use when working top of OpenShift
