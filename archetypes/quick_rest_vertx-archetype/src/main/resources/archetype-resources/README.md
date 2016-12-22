# Introduction

This project exposes a simple REST endpoint where the service greeting is available at this address http://hostname:port/greeting and returns a json Greeting message

```json
{
    "content": "Hello, World!",
    "id": 1
}
```

The id of the message is incremented for each request. To customize the message, you can pass as parameter the name of the person that you want to send your greeting.
You can perform this task in 2 different ways:

1. Build and launch using vert.x or the vert.x maven plug-in.
1. Build, deploy, and authenticate using OpenShift Online.

The id of the message is incremented for each request. To customize the message, you can pass as parameter the name of the person that you want to send your greeting.

# Prerequisites

To get started with these quickstarts you'll need the following prerequisites:

Name | Description | Version
--- | --- | ---
[java][1] | Java JDK | 8
[maven][2] | Apache Maven | 3.2.x 
[oc][3] | OpenShift Client | v3.3.x
[git][4] | Git version management | 2.x 

[1]: http://www.oracle.com/technetwork/java/javase/downloads/
[2]: https://maven.apache.org/download.cgi?Preferred=ftp://mirror.reverse.net/pub/apache/
[3]: https://docs.openshift.com/enterprise/3.2/cli_reference/get_started_cli.html
[4]: https://git-scm.com/book/en/v2/Getting-Started-Installing-Git

In order to build and deploy this project, you must have an account on an OpenShift Online (OSO): https://console.dev-preview-int.openshift.com/ instance.

# Build the Project

1. Execute the following apache maven command:

```bash
mvn clean package
```

# Launch and Test

1. Execute the following apache maven command:

    ```
    java -jar target/vertx-rest-1.0.0-SNAPSHOT.jar
    ```

1. Execute the following HTTP Get requests to get a response from the Rest endpoint:

    ```
    http http://localhost:8080/greeting
    http http://localhost:8080/greeting name==Charles
    curl http://localhost:8080/greeting
    curl http://localhost:8080/greeting?name=Bruno
    ```

# Launch using Vert.x maven plugin

1. Execute the following command:

```bash
mvn clean vertx:run
```

# OpenShift Online

1. Go to [OpenShift Online](https://console.dev-preview-int.openshift.com/console/command-line) to get the token used by the oc client for authentication and project access.
1. On the oc client, execute the following command to replace MYTOKEN with the one from the Web Console:
    ```
    oc login https://api.dev-preview-int.openshift.com --token=MYTOKEN
    ```

1. Use the Fabric8 Maven Plugin to launch the S2I process on the OpenShift Online machine and start the pod.

    ```
    mvn clean package fabric8:deploy -Popenshift -DskipTests
    ```
1. Use the Host/Port address exposed by the route to access the REST endpoint
    ```
    oc get route/vertx-rest
    NAME         HOST/PORT                                                    PATH      SERVICE           TERMINATION   LABELS
    vertx-rest   <HOST_PORT_ADDRESS>             vertx-rest:8080                 expose=true,group=org.jboss.obsidian.quickstart,project=vertx-rest,provider=fabric8,version=1.0-SNAPSHOT
    ```
1. Call the endpoint using curl or httpie tool
    ```
    http http://<HOST_PORT_ADDRESS>/greeting
    http http://<HOST_PORT_ADDRESS>/greeting name==Bruno
    
    or 
    
    curl http://<HOST_PORT_ADDRESS>/greeting
    curl http://<HOST_PORT_ADDRESS>/greeting name==Bruno
    ```


