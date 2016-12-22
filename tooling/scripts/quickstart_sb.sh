#!/usr/bin/env bash

api=${1:-https://api.engint.openshift.com}
token=${2:-b0y_AgzqOJyemigpyDS6MXOH16XTRWNPAgwXsXA7aTg}
app=${3:-http://springboot-rest-quicksb.e8ca.engint.openshiftapps.com/greeting}

echo "Quickstart - SpringBoot"
oc login $api --token=$token
oc project obsidian
oc delete project/quicksb --now=true
sleep 3
oc new-project quicksb
cd /Users/chmoulli/Code/jboss/obsidian-toaster/quickstarts/quick_rest_springboot-tomcat
mvn clean package fabric8:deploy -Popenshift -DskipTests
sleep 5
echo "Endpoint : $app"
http $app