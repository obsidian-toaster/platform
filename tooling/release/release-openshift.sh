#!/usr/bin/env bash

: ${1:?"Must specify release version. Ex: 1.0.0.Alpha1"}
api=${2:-https://api.engint.openshift.com}
token=${3:-xxxxxxxx}

REL=$1
echo "Version : $REL"

# Change version
sed -e "s/VERSION/$REL/g" ./templates/backend.yml > ./templates/backend-$REL.yml
sed -e "s/VERSION/$REL/g" ./templates/front.yml > ./templates/front-$REL.yml

# Log on to OpenShift
#oc login $api --token=$token
oc login --username=admin --password=admin
oc new-project obsidian-alpha1
#sleep 5

# Deploy the backend
echo "Deploy the backend"
oc create -f ./templates/backend-$REL.yml
oc process backend-generator-s2i | oc create -f -
oc start-build generator-backend-s2i

# Deploy the Front
echo "Deploy the frontend"
oc create -f templates/front-$REL.yml
oc process front-generator-s2i | oc create -f -
oc start-build front-generator-s2i


