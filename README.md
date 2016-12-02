# Platform

Tools used to build Obsidian (quickstart -> archetype, ...)

Fabric8 Project : https://github.com/fabric8io/ipaas-quickstarts/blob/master/ReadMe.md

## Generate the archetypes

* To build the archetypes, run this command within the project `archetype-builder` and the corresponding archetypes will be generated under the `archetypes` folder from the quickstarts

```
mvn clean compile exec:java
```

* To publish the catalog, move to the root of the project and execute this command `mvn clean install`, the catalog will be published and is generated under the project `archetypes-catalog/target/classes/archetype-catalog.xml`

* To deploy the quickstarts to the JBoss Nexus Repository, after performing the steps beforementioned, `cd archetypes/` and execute `mvn deploy` (you must have deploy privileges to Nexus, so make sure your settings.xml is properly configured)

