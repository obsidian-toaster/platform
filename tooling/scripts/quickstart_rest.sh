#!/usr/bin/env bash

#
# Prerequisites : Install jq --> https://stedolan.github.io/jq/download/
# brew install jq
#

# Example :
# OpenShift Online/Dedicated using Token --> ./quickstart_rest.sh -a api.engint.openshift.com -d e8ca -t xxxxxxxxxxxx
# Vagrant/Minishift                      --> ./quickstart_rest.sh -a HOST_IP_ADDRESS -u admin -p admin
# CI/CD OpenShift Server                 --> ./quickstart_rest.sh -a 172.16.50.40 -u admin -p admin (only available from the Red Hat VPN & access is required

while getopts a:d:t:u:p: option
do
        case "${option}"
        in
                a) api=${OPTARG};;
                d) domain=${OPTARG};;
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
JSONFILE=quickstarts.json
END=$(jq '. | length' ./quickstarts.json)
for ((c=$START;c<=$END-1; c++ ))
do
  COUNTER=$((COUNTER + 1))
  project=demo$COUNTER
	name=$(jq -r '.['$c'].name' ./$JSONFILE)
	service=$(jq -r '.['$c'].service' ./$JSONFILE)

	#
  # If the Server is an openshift online/dedicated machine, then the address of the SSO & APP should be reformated
  #
	if [[ -n $domain ]]; then
	  CONTENT=(${api//./ })
	  INSTANCE=${CONTENT[1]}
	  SUFFIX=openshiftapps
	  APP=http://$service-$project.$domain.$INSTANCE.$SUFFIX.com
	else
    APP=http://$service-$project.$api.xip.io
	fi

	echo "Git repo Name : $name to be created within the namespace/project $project"
	echo "App endpoint : $APP"

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
	oc policy add-role-to-group view system:serviceaccount -n $(oc project -q)

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

  while [ $(curl --write-out %{http_code} --silent --output /dev/null $APP/greeting) != 200 ]
   do
     echo "Wait till we get http response 200 .... from $APP/greeting"
     sleep 30
  done
  echo "SUCCESSFULLY TESTED : $GITHUB_ORG & Service $service replied : $(curl -s $APP/greeting)"

  echo "==============================="
  echo "Delete project/namespace $project"
  echo "==============================="
  oc delete project/$project

  echo "==============================="
  echo "Processing next project ...."
  echo "==============================="
  cd $CURRENT

done