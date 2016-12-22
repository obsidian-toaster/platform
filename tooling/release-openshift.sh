#!/usr/bin/env bash

: ${1:?"Must specify release version. Ex: 1.0.0.alpha1"}
api=${2:-https://api.engint.openshift.com}
token=${3:-hRXsHSHzxwjiOUFbuvkgjIg2NWNHINuEeblNxq4zZ84}

REL=$1
echo "Version : $REL"

# Change version
#sed -i -e 's/VERSION/${REL}/g' ./templates/backend.yml

#oc login $api --token=$token
