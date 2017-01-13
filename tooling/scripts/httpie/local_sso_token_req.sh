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


#echo ">>> HTTP Token query"
#echo "http --verify=no -f $SSO_HOST/auth/realms/$REALM/protocol/openid-connect/token username=$USER password=$PASSWORD client_secret=$SECRET grant_type=password client_id=$CLIENT_ID"

auth_result=$(http --verify=no -f $SSO_HOST/auth/realms/$REALM/protocol/openid-connect/token username=$USER password=$PASSWORD client_secret=$SECRET grant_type=password client_id=$CLIENT_ID)
access_token=$(echo -e "$auth_result" | awk -F"," '{print $1}' | awk -F":" '{print $2}' | sed s/\"//g | tr -d ' ')

#echo ">>> TOKEN Received"
#echo -e "$access_token"

echo ">>> Greeting"
echo "http --verify=no GET $APP/greeting 'Authorization: Bearer $access_token'"
http --verify=no GET $APP/greeting "Authorization: Bearer $access_token"

echo ">>> Greeting Customized Message"
http --verify=no GET $APP/greeting name==Spring "Authorization:Bearer $access_token"