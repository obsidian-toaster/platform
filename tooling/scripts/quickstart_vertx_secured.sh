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

oc delete project ssovertx --now=true
sleep 3
oc new-project ssovertx

rm -rf $TMPDIR/quick* && cd $TMPDIR
git clone https://github.com/obsidian-toaster-quickstarts/secured_rest-vertx.git

cd secured_rest-vertx
mvn clean install -Popenshift

cd sso
mvn fabric8:deploy -Popenshift

oc env dc/secured-vertx-rest SSO_URL=$sso
oc env dc/secured-vertx-rest REALM=master
oc env dc/secured-vertx-rest REALM_PUBLIC_KEY=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAjoVg6150oqh7csrGMsttu7r+s4YBkYDkKrg2v6Gd5NhJw9NKnFlojPnLPoDSlxpNpN2sWegexcsFdDdmtuMzTxQ3hnkFWHDDXsyfj2fKQwDjgcxg95nRaaI+/OGhWbEsGdt/A5jxg2f4Vp4VLTwCj7Ujq4hVx67vO/zbJ2k0cD2uz5T731tvqweC7H/Os+G8B1+PpH5e1jGkDPZohe4ERCEdwNcC9IAt1tPr/LKfh+84hOkE3i9mGG/LGUiJShtw7ia2jXTMb1JErlJsLJOjh+guz6OztQOICN//+rRA4AACB//+IeJ8mr/jN/dww+RfYyeAd/SId56ae8H4SE4HQQIDAQAB
oc env dc/secured-vertx-rest CLIENT_ID=demoapp
oc env dc/secured-vertx-rest SECRET=cb7a8528-ad53-4b2e-afb8-72e9795c27c8

cd ../
echo "Endpoint : $app & SSO : $sso"
while [ $(curl --write-out %{http_code} --silent --output /dev/null $app/greeting) = $http_code ]
do
  echo "Wait till we get http response : $http_code ...."
  sleep 10
done
echo "Service $app replied : $(curl -s $app)"

cd $current

echo "Call Secured endpoint"
./curl/token_req.sh $sso $app

