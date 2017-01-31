#!/usr/bin/env bash

#
# Prerequisites : Install jq --> https://stedolan.github.io/jq/download/
# brew install jq
#

# Example :
# OpenShift Online/Dedicated using Token --> ./quickstart_secured.sh -a api.engint.openshift.com -d e8ca -t xxxxxxxxxxxx
# Vagrant/Minishift                      --> ./quickstart_secured.sh -a HOST_IP_ADDRESS -u admin -p admin
# CI/CD OpenShift Server                 --> ./quickstart_secured.sh -a 172.16.50.40 -u admin -p admin (only available from the Red Hat VPN & access is required)

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
   echo "oc login $api --token=$token"
   oc login $api --token=$token
else
   echo "oc login $api -u $user -p $password"
   oc login $api:8443 -u $user -p $password
fi

#
# Read the Secured-QuickStarts json file which contains the name of the github repo to be cloned as the api address to check the service (/greeting)
#
START=0
JSONFILE=secured-quickstarts.json
END=$(jq '. | length' ./$JSONFILE)
for ((c=$START;c<=$END-1; c++ ))
do
  COUNTER=$((COUNTER + 1))
  project=secureddemo$COUNTER
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
	  SSO=https://secure-sso-$project.$domain.$INSTANCE.$SUFFIX.com
	else
    APP=http://$service-$project.$api.xip.io
    SSO=https://secure-sso-$project.$api.xip.io
	fi

	echo "Git repo Name : $name to be created within the namespace/project $project"
	echo "App endpoint : $APP"
	echo "SSO Server : $SSO"

	#
	# Create OpenShift Namespace/project
	#
	echo "==============================="
	echo "Create OpenShift Project"
	echo "==============================="
	oc new-project $project

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
  mvn clean install -Popenshift
  cd sso
  mvn fabric8:deploy -Popenshift

  #
  # Set ENV var for Vert.x, SpringBoot
  # TODO : should be improved & externalized
  #
  case $name in
    *"springboot"*)
        echo "Set env var for Spring Boot"
        oc env dc/secured-springboot-rest SSO_URL=$SSO/auth
        ;;
    *"vertx"*)
        echo "Set env var for Vert.x"
        oc env dc/secured-vertx-rest SSO_URL=$SSO
        oc env dc/secured-vertx-rest REALM=master
        oc env dc/secured-vertx-rest REALM_PUBLIC_KEY=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAjoVg6150oqh7csrGMsttu7r+s4YBkYDkKrg2v6Gd5NhJw9NKnFlojPnLPoDSlxpNpN2sWegexcsFdDdmtuMzTxQ3hnkFWHDDXsyfj2fKQwDjgcxg95nRaaI+/OGhWbEsGdt/A5jxg2f4Vp4VLTwCj7Ujq4hVx67vO/zbJ2k0cD2uz5T731tvqweC7H/Os+G8B1+PpH5e1jGkDPZohe4ERCEdwNcC9IAt1tPr/LKfh+84hOkE3i9mGG/LGUiJShtw7ia2jXTMb1JErlJsLJOjh+guz6OztQOICN//+rRA4AACB//+IeJ8mr/jN/dww+RfYyeAd/SId56ae8H4SE4HQQIDAQAB
        oc env dc/secured-vertx-rest CLIENT_ID=demoapp
        oc env dc/secured-vertx-rest SECRET=cb7a8528-ad53-4b2e-afb8-72e9795c27c8
        ;;
    *"swarm"*)
        echo "Set env var for WildFly Swarm"
        oc env dc/secured-swarm-rest SSO_URL=$SSO
        oc env dc/secured-swarm-rest REALM=master
        oc env dc/secured-swarm-rest REALM_PUBLIC_KEY=MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAjoVg6150oqh7csrGMsttu7r+s4YBkYDkKrg2v6Gd5NhJw9NKnFlojPnLPoDSlxpNpN2sWegexcsFdDdmtuMzTxQ3hnkFWHDDXsyfj2fKQwDjgcxg95nRaaI+/OGhWbEsGdt/A5jxg2f4Vp4VLTwCj7Ujq4hVx67vO/zbJ2k0cD2uz5T731tvqweC7H/Os+G8B1+PpH5e1jGkDPZohe4ERCEdwNcC9IAt1tPr/LKfh+84hOkE3i9mGG/LGUiJShtw7ia2jXTMb1JErlJsLJOjh+guz6OztQOICN//+rRA4AACB//+IeJ8mr/jN/dww+RfYyeAd/SId56ae8H4SE4HQQIDAQAB
        oc env dc/secured-swarm-rest CLIENT_ID=demoapp
        oc env dc/secured-swarm-rest SECRET=cb7a8528-ad53-4b2e-afb8-72e9795c27c8
        ;;
  esac

  #
  # Wait till the SSO server replies
  #
  echo "==============================="
  echo "Call SSO server : $SSO"
  echo "==============================="

  while [ $(curl -k --write-out %{http_code} --silent --output /dev/null $SSO) != 200 ]
   do
     echo "Wait till SSO server is up & running"
     sleep 30
  done

  #
  # Issue Request against the App using the Token issued by the Red Hat SSO Server
  #
  echo "==============================="
  echo " Call the Secured Service : $APP/greting" using token issued by the SSO Server
  echo "==============================="
  cd $CURRENT
  echo "Call Secured endpoint using the Token issued by the Red Hat SSO Server"
  REALM=master
  USER=admin
  PASSWORD=admin
  CLIENT_ID=demoapp
  SECRET=cb7a8528-ad53-4b2e-afb8-72e9795c27c8

  replied="false"
  while ! $replied; do
     echo "Wait till we get http response 200 .... from $APP/greeting"
     auth_result=$(curl -sk -X POST $SSO/auth/realms/$REALM/protocol/openid-connect/token -d grant_type=password -d username=$USER -d client_secret=$SECRET -d password=$PASSWORD -d client_id=$CLIENT_ID)
     access_token=$(echo -e "$auth_result" | awk -F"," '{print $1}' | awk -F":" '{print $2}' | sed s/\"//g | tr -d ' ')
     result=$(curl --write-out %{http_code} --silent --output /dev/null $APP/greeting -H "Authorization:Bearer $access_token")
     if [ $result = 200 ]; then
       replied=true
     else
       sleep 30
     fi
  done
  echo "==============================="
  echo "SUCCESSFULLY TESTED : $GITHUB_ORG & Service $service replied"
  echo "==============================="

  echo "==============================="
  echo "Delete project/namespace $project"
  echo "==============================="
  oc delete project/$project

  echo "==============================="
  echo "Processing next project ...."
  echo "==============================="

done