#!/usr/bin/env bash

# Example :
# Token         --> quickstart_vertx.sh -a https://api.engint.openshift.com -t xxxxxxxxxxxx -c http://vertx-rest-quickvertx.e8ca.engint.openshiftapps.com/greeting
# User/password --> quickstart_vertx.sh -a https://172.16.50.40:8443 -u admin -p admin -c http://vertx-rest-quickvertx.172.16.50.40.xip.io/greeting

while getopts a:t:u:p:c: option
do
        case "${option}"
        in
                a) api=${OPTARG};;
                t) token=${OPTARG};;
                u) user=${OPTARG};;
                p) password=${OPTARG};;
                c) app=${OPTARG};;
        esac
done

current=$PWD
http_code=200

echo "Quickstart - Vertx"
if [ "$token" != "" ]; then
   oc login $api --token=$token
else
   echo "oc login $api -u $user -p $password"
   oc login $api -u $user -p $password
fi

http_code=200
current=$PWD

oc project default
oc delete project quickvertx --now=true
sleep 3
oc new-project quickvertx

cd $TMPDIR
git clone https://github.com/obsidian-toaster-quickstarts/quick_rest_vertx.git
cd quick_rest_vertx

mvn clean package fabric8:deploy -Popenshift -DskipTests
echo "Endpoint : $app"
while [ $(curl --write-out %{http_code} --silent --output /dev/null $app) != 200 ]
do
  echo "Wait till we get http response 200 ...."
  sleep 3
done
echo "Service $app replied : $(curl -s $app)"

cd $current
oc project default