#!/usr/bin/env bash

REALM=master
USER=admin
PASSWORD=admin
CLIENT_ID=vertx
SECRET=ffdf9fec-aff3-4e22-bde1-8168aa9e24f6
SSO_HOST=${1:-http://localhost:9080}
APP=${2:-http://localhost:8080}

function jsonValue() {
  KEY=$1
  num=$2
  awk -F"[,:}]" '{for(i=1;i<=NF;i++){if($i~/'$KEY'\042/){print $(i+1)}}}' | tr -d '"' | sed -n ${num}p
}

echo "curl -vsk -X POST $SSO_HOST/auth/realms/$REALM/protocol/openid-connect/token -d grant_type=password -d username=$USER -d client_secret=$SECRET -d password=$PASSWORD -d client_id=$CLIENT_ID"
auth_result=$(curl -sk -X POST $SSO_HOST/auth/realms/$REALM/protocol/openid-connect/token -d grant_type=password -d username=$USER -d client_secret=$SECRET -d password=$PASSWORD -d client_id=$CLIENT_ID)
access_token=$(echo -e "$auth_result" | awk -F"," '{print $1}' | awk -F":" '{print $2}' | sed s/\"//g | tr -d ' ')

#echo ">>> TOKEN Received"
#echo $access_token

echo ">>> Greeting"
echo "curl -k $APP/greeting -H Authorization:Bearer $access_token"
curl -k $APP/greeting -H "Authorization:Bearer $access_token"

echo ">>> Greeting Customized Message"
echo "curl -k $APP/greeting?name=Spring -H Authorization:Bearer $access_token"
curl -k $APP/greeting?name=Spring -H "Authorization:Bearer $access_token"