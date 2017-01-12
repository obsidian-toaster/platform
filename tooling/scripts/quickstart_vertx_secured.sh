#!/usr/bin/env bash

# Example :
# Token                         --> ./quickstart_vertx_secured.sh -a https://api.engint.openshift.com -t xxxxxxxxxxxx -c http://secured-vertx-rest-ssovertx.e8ca.engint.openshiftapps.com/greeting -s https://secure-sso-ssovertx.e8ca.engint.openshiftapps.com
# User/password                 --> ./quickstart_vertx_secured.sh -a https://172.16.50.40:8443 -u admin -p admin -c http://secured-vertx-rest-ssovertx.172.16.50.40.xip.io/greeting -s https://secure-sso-ssovertx.172.16.50.40.xip.io
# User/password (local vagrant) --> ./quickstart_vertx_secured.sh -a 172.28.128.4:8443 -u admin -p admin -c http://secured-vertx-rest-ssovertx.172.28.128.4.xip.io/greeting -s https://secure-sso-ssovertx.172.28.128.4.xip.io

while getopts a:t:u:p:c:s: option
do
        case "${option}"
        in
                a) api=${OPTARG};;
                t) token=${OPTARG};;
                u) user=${OPTARG};;
                p) password=${OPTARG};;
                c) app=${OPTARG};;
                s) sso=${OPTARG};;
        esac
done

current=$PWD
http_code=200

echo "# Quickstart - Secured Vert.x with Red Hat SSO"
if [ "$token" != "" ]; then
   oc login $api --token=$token
else
   echo "oc login $api -u $user -p $password"
   oc login $api -u $user -p $password
fi

oc project default
oc delete project ssovertx --now=true
sleep 3
oc new-project ssovertx

rm -rf $TMPDIR/quick* && cd $TMPDIR
git clone https://github.com/obsidian-toaster-quickstarts/quick_secured_rest-vertx.git
cd quick_secured_rest-vertx

mvn clean install
cd sso
mvn fabric8:deploy
oc env dc/secured-vertx-rest SSO_URL=$sso
oc env dc/secured-vertx-rest REALM=master
oc env dc/secured-vertx-rest REALM_PUBLIC_KEY=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAjSLQrbpwNkpuNc+LxcrG711/oIsqUshISLWjXALgx6/L7NItNrPjJTwzqtWCTJrl0/eQLcPdi7UeZA1qjPGa1l+AIj+FnLyCOl7gm65xB3xUpRuGNe5mJ9a+ZtzprXOKhd0WRC8ydiMwyFxIQJPjt7ywlNvU0hZR1U3QboLRICadP5WPaoYNOaYmpkX34r+kegVfdga+1xqG6Ba5v2/9rRg74KxJubCQxcinbH7gVIYSyFQPP5OpBo14SuynFL1YhWDpgUhLz7gr60sG+RC5eC0zuvCRTELn+JquSogPUopuDej/Sd3T5VYHIBJ8P4x4MIz9/FDX8bOFwM73nHgL5wIDAQAB
oc env dc/secured-vertx-rest CLIENT_ID=demoapp
oc env dc/secured-vertx-rest SECRET=cb7a8528-ad53-4b2e-afb8-72e9795c27c8
cd ../
echo "Endpoint : $app & SSO : $sso"
while [ $(curl --write-out %{http_code} --silent --output /dev/null $app) != 200 ]
do
  echo "Wait till we get http response 200 ...."
  sleep 3
done
echo "Service $app replied : $(curl -s $app)"

cd $current
oc project default

