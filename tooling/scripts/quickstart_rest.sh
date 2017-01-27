#!/usr/bin/env bash

#
# Prerequisites : Install jq --> https://stedolan.github.io/jq/download/
# brew install jq

# Example :
# OSO     : Token           --> ./quickstart_rest.sh -a api.engint.openshift.com -t xxxxxxxxxxxx
# Vagrant : User/password   --> ./quickstart_rest.sh -a 172.28.128.4 -u admin -p admin
# Minishift : User/password --> ./quickstart_rest.sh -a 192.168.64.25 -u admin -p admin
# CI/CD Server ./quickstart_rest.sh -a 172.16.50.40 -u admin -p admin

while getopts a:t:u:p: option
do
        case "${option}"
        in
                a) api=${OPTARG};;
                t) token=${OPTARG};;
                u) user=${OPTARG};;
                p) password=${OPTARG};;
        esac
done

current=$PWD
counter=0

echo "Log on to OpenShift Machine"
if [ "$token" != "" ]; then
   oc login $api:8443 --token=$token
else
   echo "oc login $api -u $user -p $password"
   oc login $api:8443 -u $user -p $password
fi

#
# Read the quickstarts json file which contains the name of the github repos to be cloned as the api address to check if the service replies
#
START=0
END=$(jq '. | length' ./quickstarts.json)
for ((c=$START;c<=$END-1; c++ ))
do
  COUNTER=$((COUNTER + 1))
  project=demo$COUNTER
	name=$(jq -r '.['$c'].name' ./quickstarts.json)
	service=$(jq -r '.['$c'].service' ./quickstarts.json)
	app=http://$service-$project.$api.xip.io/
	echo "Git repo Name : $name to be created within the namespace/project $project"
	echo "App endpoint : $app"

	#
	# Create OpenShift Namespace/project
	#
	oc new-project $project

  #
  # Git clone the Quickstart
  #
  rm -rf $TMPDIR/$name && cd $TMPDIR
  git clone https://github.com/obsidian-toaster-quickstarts/$name.git
  cd $name

  #
  # Compile project & deploy within the namespace $project under OpenShift
  #
  mvn clean package fabric8:deploy -DskipTests -Popenshift

  echo "Press any key to continue & test the service ..."
  read junk

  #
  # Wait till the Service replies
  #
  echo "Endpoint : $app"
  while [ $(curl --write-out %{http_code} --silent --output /dev/null $app/greeting) != 200 ]
   do
     echo "Wait till we get http response 200 ...."
     sleep 10
  done
  echo "Service $service replied : $(curl -s $app/greeting)"

  cd $current
  oc delete project/$project
done