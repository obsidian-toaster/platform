#!/usr/bin/env bash

api=${1:-https://api.engint.openshift.com}
token=${2:-b0y_AgzqOJyemigpyDS6MXOH16XTRWNPAgwXsXA7aTg}
app=${3:-http://springboot-rest-quicksb.e8ca.engint.openshiftapps.com/greeting}
current=$PWD
http_code=200

echo "Quickstart - SpringBoot"
oc login $api --token=$token
oc project obsidian
oc delete project quicksb --now=true
sleep 3
oc new-project quicksb

cd $TMPDIR
git clone https://github.com/obsidian-toaster-quickstarts/quick_rest_springboot-tomcat.git
cd quick_rest_springboot-tomcat

cd /Users/chmoulli/Code/jboss/obsidian-toaster/quickstarts/quick_rest_springboot-tomcat
mvn clean package fabric8:deploy -Popenshift -DskipTests
echo "Endpoint : $app"
while [ $(curl --write-out %{http_code} --silent --output /dev/null $app) != 200 ]
do
  echo "Wait till we get http response 200 ...."
  sleep 3
done
echo "Service $app replied : $(curl -s $app)"

cd $current
oc project obsidian