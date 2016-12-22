#!/usr/bin/env bash

api=${1:-https://api.engint.openshift.com}
token=${2:-b0y_AgzqOJyemigpyDS6MXOH16XTRWNPAgwXsXA7aTg}
sso=${3:-https://secure-sso-vertx.e8ca.engint.openshiftapps.com}
app=${4:-http://secured-vertx-rest-vertx.e8ca.engint.openshiftapps.com}

echo "Quickstart - Secured Vertx with Red Hat SSO"
oc login $api --token=$token
oc project obsidian
oc delete project/ssovertx --now=true
sleep 3
oc new-project ssovertx
mvn clean install
cd sso
mvn fabric8:deploy
oc env dc/secured-vertx-rest SSO_URL=$sso
oc env dc/secured-vertx-rest REALM=master
oc env dc/secured-vertx-rest REALM_PUBLIC_KEY=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAjSLQrbpwNkpuNc+LxcrG711/oIsqUshISLWjXALgx6/L7NItNrPjJTwzqtWCTJrl0/eQLcPdi7UeZA1qjPGa1l+AIj+FnLyCOl7gm65xB3xUpRuGNe5mJ9a+ZtzprXOKhd0WRC8ydiMwyFxIQJPjt7ywlNvU0hZR1U3QboLRICadP5WPaoYNOaYmpkX34r+kegVfdga+1xqG6Ba5v2/9rRg74KxJubCQxcinbH7gVIYSyFQPP5OpBo14SuynFL1YhWDpgUhLz7gr60sG+RC5eC0zuvCRTELn+JquSogPUopuDej/Sd3T5VYHIBJ8P4x4MIz9/FDX8bOFwM73nHgL5wIDAQAB
oc env dc/secured-vertx-rest CLIENT_ID=demoapp
oc env dc/secured-vertx-rest SECRET=cb7a8528-ad53-4b2e-afb8-72e9795c27c8
cd ../
sleep 3
./scripts/httpie/token_req.sh $sso $app

