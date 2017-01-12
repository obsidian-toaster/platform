#!/usr/bin/env bash

# Example :
# Token                         --> ./quickstart_sb.sh -a https://api.engint.openshift.com -t xxxxxxxxxxxx -c http://springboot-rest-quicksb.e8ca.engint.openshiftapps.com/greeting
# User/password (CI Server)     --> ./quickstart_sb.sh -a https://172.16.50.40:8443 -u admin -p admin -c http://springboot-rest-quicksb.172.16.50.40.xip.io/greeting
# User/password (local vagrant) --> ./quickstart_sb.sh -a 172.28.128.4:8443 -u admin -p admin -c http://springboot-rest-quicksb.172.28.128.4.xip.io/greeting

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

echo "Quickstart - SpringBoot"
if [ "$token" != "" ]; then
   oc login $api --token=$token
else
   echo "oc login $api -u $user -p $password"
   oc login $api -u $user -p $password
fi

oc project default
oc delete project quicksb --now=true
sleep 3
oc new-project quicksb

rm -rf $TMPDIR/quick*.git && cd $TMPDIR
git clone https://github.com/obsidian-toaster-quickstarts/quick_rest_springboot-tomcat.git
cd quick_rest_springboot-tomcat

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