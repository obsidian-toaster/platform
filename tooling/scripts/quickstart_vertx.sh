#!/usr/bin/env bash

# Example :
# OSO     : Token           --> ./quickstart_vertx.sh -n quickvertx -a https://api.engint.openshift.com -t xxxxxxxxxxxx -c http://vertx-rest-quickvertx.e8ca.engint.openshiftapps.com
# Minishift : User/password --> ./quickstart_vertx.sh -n quickvertx -a 172.28.128.4:8443 -u admin -p admin -c http://vertx-rest-quickvertx.172.28.128.4.xip.io

while getopts n:a:t:u:p:c: option
do
        case "${option}"
        in
                n) project=${OPTARG};;
                a) api=${OPTARG};;
                t) token=${OPTARG};;
                u) user=${OPTARG};;
                p) password=${OPTARG};;
                c) app=${OPTARG};;
        esac
done

current=$PWD

echo "Quickstart - Vert.x"
if [ "$token" != "" ]; then
   oc login $api --token=$token
else
   echo "oc login $api -u $user -p $password"
   oc login $api -u $user -p $password
fi

#
# Create project/namespace $project if it doesn't exist otherwise delete all resources
#
status=$(oc get project $project -o yaml | grep phase)
if [[ $status == *"Active"* ]]; then
    echo "Project $project already exist. We will delete all the resources"
    oc project $project
    oc delete all --all -n $project
else
    echo "Project $project doesn't exist. We will create it"
    oc new-project $project
fi

#
# Git clone the Quickstart
#
rm -rf $TMPDIR/* && cd $TMPDIR
gitRepo=rest_vertx
git clone https://github.com/obsidian-toaster-quickstarts/$gitRepo.git
cd $gitRepo

#
# Compile project
#
mvn clean package fabric8:deploy -Popenshift -DskipTests

#
# Wait till the Service replies
#
echo "Endpoint : $app"
while [ $(curl --write-out %{http_code} --silent --output /dev/null $app/greeting) != 200 ]
do
  echo "Wait till we get http response 200 ...."
  sleep 10
done
echo "Service $app replied : $(curl -s $app)"

cd $current