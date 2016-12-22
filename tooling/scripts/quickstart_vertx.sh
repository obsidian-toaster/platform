#!/usr/bin/env bash

api=${1:-https://api.engint.openshift.com}
token=${2:-b0y_AgzqOJyemigpyDS6MXOH16XTRWNPAgwXsXA7aTg}
app=${3:-vertx-rest-quickvertx.e8ca.engint.openshiftapps.com/greeting}

echo "Quickstart - Vertx"
oc login $api --token=$token
oc delete project/quickvertx
oc project obsidian
sleep 3
oc new-project quickvertx
mvn clean package fabric8:deploy -Popenshift -DskipTests
sleep 3
oc get route/vertx-rest
http $app