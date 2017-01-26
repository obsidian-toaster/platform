#!/usr/bin/env bash

# Example :
# OSO     : Token         --> ./quickstart_sb_secured.sh -n sso -a https://api.engint.openshift.com -t xxxxxxxxx -c http://secured-springboot-rest-sso.e8ca.engint.openshiftapps.com -s https://secure-sso-sso.e8ca.engint.openshiftapps.com
# Vagrant : User/password --> ./quickstart_sb_secured.sh -n sso -a 172.28.128.4:8443 -u admin -p admin -c http://secured-springboot-rest-sso.172.28.128.4.xip.io -s https://secure-sso-sso.172.28.128.4.xip.io
# Minishift (1.0.0.Beta2) --> ./quickstart_sb_secured.sh -n sso -a 192.168.99.101:8443 -u admin -p admin -c http://secured-springboot-rest-sso.192.168.99.101.xip.io -s https://secure-sso-sso.192.168.99.101.xip.io
#
# ./httpie/token_req.sh https://secure-sso-sso.192.168.99.101.xip.io http://secured-springboot-rest-sso.192.168.99.101.xip.io


while getopts n:a:t:u:p:c:s: option
do
        case "${option}"
        in
                n) project=${OPTARG};;
                a) api=${OPTARG};;
                t) token=${OPTARG};;
                u) user=${OPTARG};;
                p) password=${OPTARG};;
                c) app=${OPTARG};;
                s) sso=${OPTARG};;
        esac
done

current=$PWD
echo "================================================================================"
echo "Openshift --> Api: $api, Token: $token, User: $user, Password: $password"
echo "App: $app"
echo "sso: $sso"
echo "================================================================================"

echo "# Quickstart - Secured Spring Boot with Red Hat SSO"
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
gitRepo=secured_rest-springboot
rm -rf $TMPDIR/$gitRepo && cd $TMPDIR
git clone https://github.com/obsidian-toaster-quickstarts/$gitRepo.git

#
# Compile project
#
cd $gitRepo
mvn clean install -Popenshift

#
# Deploy using fabric8 maven plugin the OpenShift objects
#
cd sso
mvn fabric8:deploy -Popenshift

#
# Set the ENV var to configure the App to access the Red Hat SSO
#
oc env dc/secured-springboot-rest SSO_URL=$sso/auth

#
# Wait till the SSO Server replies
#
cd ../
sleep 5
echo "Endpoint : $app & SSO : $sso"
while [ $(curl --write-out %{http_code} --silent --output /dev/null $sso) != 200 ]
do
  echo "Wait till SSO Server is up ...."
  sleep 10
done

#
# Issue Request against the App using the Token issued by the Red Hat SSO Server
#
cd $current
echo "Call Secured endpoint using the Token issued by the Red Hat SSO Server"
./curl/token_req.sh $sso $app