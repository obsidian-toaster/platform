#!/usr/bin/env bash

api=${1:-https://api.engint.openshift.com}
token=${2:-b0y_AgzqOJyemigpyDS6MXOH16XTRWNPAgwXsXA7aTg}
app=${3:-http://springboot-rest-quicksb.e8ca.engint.openshiftapps.com/greeting}

echo "Quickstart - SpringBoot"
oc login $api --token=$token
oc delete project/quicksb
oc project obsidian
sleep 3
oc new-project quicksb
mvn clean package fabric8:deploy -Popenshift -DskipTests
sleep 3
oc get route/springboot-rest
http $app