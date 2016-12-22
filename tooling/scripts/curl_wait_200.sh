#!/usr/bin/env bash

app=vertx-rest-quickvertx.e8ca.engint.openshiftapps.com/greeting

http_code=200
while [ $(curl --write-out %{http_code} --silent --output /dev/null $app) != 200 ]
do
  echo "Wait till we get http response 200 ...."
  sleep 1
done
echo "Service $app replied : $(curl -s $app)"

