#!/usr/bin/env bash

: ${1:?"Must specify release version. Ex: 1.0.0.alpha1"}
api=${2:-https://api.engint.openshift.com}
token=${3:-hRXsHSHzxwjiOUFbuvkgjIg2NWNHINuEeblNxq4zZ84}

REL=$1
echo "Version : $REL"

# Change version
sed -i -e "s/VERSION/$REL/g" ./templates/backend.yml > ./templates/backend-$REL.yml
sed -i -e "s/VERSION/$REL/g" ./templates/front.yml > ./templates/front-$REL.yml

# Log on to OpenShift
oc login $api --token=$token

oc new-project obsidian-alpha1

# Deploy the backend
oc create -f ./templates/backend-$REL.yml
oc process backend-generator-s2i | oc create -f -
oc start-build generator-backend-s2i

# Deploy the Front
oc create -f templates/front-$REL.yml
oc process front-generator-s2i | oc create -f -
oc start-build front-generator


