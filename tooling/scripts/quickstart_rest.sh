#!/usr/bin/env bash

#
# Prerequisites : Install jq --> https://stedolan.github.io/jq/download/
# brew install jq
#

# Example :
# OpenShift Online/Dedicated using Token --> ./quickstart_rest.sh -a api.engint.openshift.com -t xxxxxxxxxxxx
# Vagrant/Minishift                      --> ./quickstart_rest.sh -a HOST_IP_ADDRESS -u admin -p admin
# CI/CD OpenShift Server                 --> ./quickstart_rest.sh -a 172.16.50.40 -u admin -p admin (only available from the Red Hat VPN & access is required

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

CURRENT=$PWD
GITHUB_ORG=http://github.com/obsidian-toaster-quickstarts

echo "Log on to OpenShift Machine"
if [ "$token" != "" ]; then
   oc login $api:8443 --token=$token
else
   echo "oc login $api -u $user -p $password"
   oc login $api:8443 -u $user -p $password
fi

#
# Read the QuickStarts json file which contains the name of the github repo to be cloned as the api address to check the service (/greeting)
#
START=0
END=$(jq '. | length' ./quickstarts.json)
for ((c=$START;c<=$END-1; c++ ))
do
  COUNTER=$((COUNTER + 1))
  project=demo$COUNTER
	name=$(jq -r '.['$c'].name' ./quickstarts.json)
	service=$(jq -r '.['$c'].service' ./quickstarts.json)
	app=http://$service-$project.$api.xip.io

	echo "Git repo Name : $name to be created within the namespace/project $project"
	echo "App endpoint : $app"

	#
	# Create OpenShift Namespace/project
	#
	echo "==============================="
	echo "Create OpenShift Project"
	echo "==============================="
	oc new-project $project

	#
	# Add role to user view system:serviceaccount which is required to access ConfigMap (f-m-p)
	#
	echo "==============================="
	echo "Add role to user"
	echo "==============================="
	oc policy add-role-to-user view system:serviceaccount:$(oc project -q):default -n $(oc project -q)

  #
  # Git clone the Quickstart
  #
  echo "==============================="
  echo "git clone project : $GITHUB_ORG/$name.git"
  echo "==============================="
  rm -rf $TMPDIR/$name && cd $TMPDIR
  git clone $GITHUB_ORG/$name.git
  cd $name

  #
  # Compile project & deploy within the namespace $project under OpenShift
  #
  echo "==============================="
  echo "Build & deploy on openshift"
  echo "==============================="
  mvn clean package fabric8:deploy -DskipTests -Popenshift

  #
  # Wait till the Service replies
  #
  echo "==============================="
  echo "Call service"
  echo "==============================="

  while [ $(curl --write-out %{http_code} --silent --output /dev/null $app/greeting) != 200 ]
   do
     echo "Wait till we get http response 200 .... from $app/greeting"
     sleep 30
  done
  echo "SUCCESSFULLY TESTED : $GITHUB_ORG & Service $service replied : $(curl -s $app/greeting)"

  echo "==============================="
  echo "Processing next project ...."
  echo "==============================="

  cd $CURRENT

  echo "==============================="
  echo "Delete project/namespace $project"
  echo "==============================="
  oc delete project/$project
done