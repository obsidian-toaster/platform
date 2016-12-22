#!/usr/bin/env bash

api=${1:-https://api.engint.openshift.com}
token=${2:-b0y_AgzqOJyemigpyDS6MXOH16XTRWNPAgwXsXA7aTg}
sso=${3:-https://secure-sso-sso.e8ca.engint.openshiftapps.com/auth}
app=${4:-http://secured-springboot-rest-sso.e8ca.engint.openshiftapps.com}

echo "# Quickstart - Secured Spring Boot with Red Hat SSO"
oc login $api --token=$token
oc delete project/sso
oc project obsidian
sleep 3
oc new-project sso
mvn clean install -Popenshift
cd sso
mvn fabric8:deploy -Popenshift
oc env dc/secured-springboot-rest SSO_URL=$sso
cd ../
sleep 5
./scripts/httpie/token_req.sh $sso $app