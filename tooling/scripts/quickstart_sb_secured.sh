#!/usr/bin/env bash

api=${1:-https://api.engint.openshift.com}
token=${2:-b0y_AgzqOJyemigpyDS6MXOH16XTRWNPAgwXsXA7aTg}
sso=${3:-https://secure-sso-sso.e8ca.engint.openshiftapps.com/auth}
app=${4:-http://secured-springboot-rest-sso.e8ca.engint.openshiftapps.com}

echo "# Quickstart - Secured Spring Boot with Red Hat SSO"
oc login $api --token=$token
oc project obsidian
oc delete project/sso --now=true
sleep 3
oc new-project sso
cd /Users/chmoulli/Code/jboss/obsidian-toaster/quickstarts/quick_rest_secured_springboot
mvn clean install -Popenshift
cd sso
mvn fabric8:deploy -Popenshift
oc env dc/secured-springboot-rest SSO_URL=$sso
cd ../
sleep 5
echo "Endpoint : $app & SSO : $sso"
while [ $(curl --write-out %{http_code} --silent --output /dev/null $app) != 200 ]
do
  echo "Wait till we get http response 200 ...."
  sleep 3
done
echo "Service $app replied : $(curl -s $app)"