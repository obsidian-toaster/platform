#!/usr/bin/env bash

# Example :
# Token                         --> ./quickstart_vertx_secured.sh -a https://api.engint.openshift.com -t xxxxxxxxxxxx -c http://secured-vertx-rest-ssovertx.e8ca.engint.openshiftapps.com -s https://secure-sso-ssovertx.e8ca.engint.openshiftapps.com
# User/password                 --> ./quickstart_vertx_secured.sh -a https://172.16.50.40:8443 -u admin -p admin -c http://secured-vertx-rest-ssovertx.172.16.50.40.xip.io -s https://secure-sso-ssovertx.172.16.50.40.xip.io
# User/password (local vagrant) --> ./quickstart_vertx_secured.sh -a 172.28.128.4:8443 -u admin -p admin -c http://secured-vertx-rest-ssovertx.172.28.128.4.xip.io -s https://secure-sso-ssovertx.172.28.128.4.xip.io
# Minishift                     --> ./quickstart_vertx_secured.sh -a 192.168.64.25:8443 -u admin -p admin -c http://secured-vertx-rest-ssovertx.192.168.64.25:8443.xip.io -s https://secure-sso-ssovertx.192.168.64.25:8443.xip.io
#
# ./httpie/token_req.sh https://secure-sso-ssovertx.172.28.128.4.xip.io http://secured-vertx-rest-ssovertx.172.28.128.4.xip.io

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
http_code=401
echo "================================================================================"
echo "Openshift --> Api: $api, Token: $token, User: $user, Password: $password"
echo "App: $app"
echo "sso: $sso"
echo "================================================================================"

echo "# Quickstart - Secured Vert.x with Red Hat SSO"
if [ "$token" != "" ]; then
   oc login $api --token=$token
else
   echo "oc login $api -u $user -p $password"
   oc login $api -u $user -p $password
fi

project=ssovertx
status=$(oc get project $project -o yaml | grep phase)
if [[ $status == *"Active"* ]]; then
    echo "Project $project already exist. We will delete all the resources"
    oc delete all --all -n $project
    sleep 3
else
    echo "Project $project doesn't exist. We will create it"
    oc new-project $project
fi

