#!/usr/bin/env bash

#
# Prerequisites : Install jq --> https://stedolan.github.io/jq/download/
# brew install jq

# Example :
# OSO     : Token           --> ./quickstart_sb.sh -a https://api.engint.openshift.com -t xxxxxxxxxxxx -c http://springboot-rest-quicksb.e8ca.engint.openshiftapps.com
# Vagrant : User/password   --> ./quickstart_sb.sh -a 172.28.128.4:8443 -u admin -p admin -c http://springboot-rest-quicksb.172.28.128.4.xip.io
# Minishift : User/password --> ./quickstart_sb.sh -a 192.168.64.25:8443 -u admin -p admin -c http://springboot-rest-quicksb.192.168.64.25.xip.io

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
   oc login $api --token=$token
else
   echo "oc login $api -u $user -p $password"
   oc login $api -u $user -p $password
fi

START=0
END=$(jq '. | length' ./quickstarts.json)
for ((c=$START;c<=$END-1; c++ ))
do
  COUNTER=$((COUNTER + 1))
  project=demo$COUNTER
	name=$(jq -r '.['$c'].name' ./quickstarts.json)
	service=$(jq -r '.['$c'].service' ./quickstarts.json)
	echo "Git repo Name : $name, service: $service - to be created within the project : project$((counter+1))"

  #
  # Git clone the Quickstart
  #
  rm -rf $TMPDIR/$name && cd $TMPDIR
  git clone https://github.com/obsidian-toaster-quickstarts/$name.git
  cd $gitRepo

  #
  # Compile project
  #
  # mvn clean package fabric8:deploy -Popenshift -DskipTests
#
  # #
  # # Wait till the Service replies
  # #
  # echo "Endpoint : $app"
  # while [ $(curl --write-out %{http_code} --silent --output /dev/null $app/greeting) != 200 ]
  # do
  #   echo "Wait till we get http response 200 ...."
  #   sleep 10
  # done
  # echo "Service $app replied : $(curl -s $app/greeting)"

  cd $current
done