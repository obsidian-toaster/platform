#!/usr/bin/env bash

# Example :
# Token         --> quickstart_sb_secured.sh -a https://api.engint.openshift.com -t xxxxxxxxxxxx -c http://secured-springboot-rest-sso.e8ca.engint.openshiftapps.com/greeting -s https://secure-sso-sso.e8ca.engint.openshiftapps.com/auth
# User/password --> quickstart_sb_secured.sh -a https://172.16.50.40:8443 -u admin -p admin -c http://secured-springboot-rest-sso.172.16.50.40.xip.io/greeting -s https://secure-sso-sso.172.16.50.40.xip.io/auth

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

echo "# Quickstart - Secured Spring Boot with Red Hat SSO"
if [ "$token" != "" ]; then
   oc login $api --token=$token
else
   echo "oc login $api -u $user -p $password"
   oc login $api -u $user -p $password
fi

oc project default
oc delete project sso --now=true
sleep 5
oc new-project sso

cd $TMPDIR
git clone https://github.com/obsidian-toaster-quickstarts/quick_secured_rest-springboot.git
cd quick_secured_rest-springboot

mvn clean install -Popenshift
cd sso
mvn fabric8:deploy -Popenshift
oc env dc/secured-springboot-rest SSO_URL=$sso
cd ../
sleep 5
echo "Endpoint : $app & SSO : $sso"
while [ $(curl --write-out %{http_code} --silent --output /dev/null $app) != 404 ]
do
  echo "Wait till we get http response 200 ...."
  sleep 3
done
./curl/token_req.sh $sso $app
echo "Service $app replied"

cd $current
oc project default