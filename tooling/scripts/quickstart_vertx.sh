#!/usr/bin/env bash

api=${1:-https://api.engint.openshift.com}
token=${2:-b0y_AgzqOJyemigpyDS6MXOH16XTRWNPAgwXsXA7aTg}
app=${3:-vertx-rest-quickvertx.e8ca.engint.openshiftapps.com/greeting}

echo "Quickstart - Vertx"
oc login $api --token=$token
oc project obsidian
oc delete project/quickvertx --now=true
sleep 3
oc new-project quickvertx
cd /Users/chmoulli/Code/jboss/obsidian-toaster/quickstarts/quick_rest_vertx
mvn clean package fabric8:deploy -Popenshift -DskipTests
sleep 3
echo "Endpoint : $app"
http $app