#!/usr/bin/env bash

# Example :
# Token                         --> ./release-openshift.sh -a https://api.engint.openshift.com -t xxxxxxxxxxxx -v 1.0.0.Alpha1 -g obsidian-toaster
# User/password (CI Server)     --> ./release-openshift.sh -a https://172.16.50.40:8443 -u admin -p admin  -v 1.0.0.Alpha1 -g obsidian-toaster
# User/password (local vagrant) --> ./release-openshift.sh -a 172.28.128.4:8443 -u admin -p admin  -v 1.0.0.Dummy -b backend-generator-obsidian-dummy.172.28.128.4.xip.io -g obsidian-tester

while getopts a:t:u:p:v:b: option
do
        case "${option}"
        in
                a) api=${OPTARG};;
                t) token=${OPTARG};;
                u) user=${OPTARG};;
                p) password=${OPTARG};;
                v) version=${OPTARG};;
                b) backendurl=${OPTARG};;
                o) githuborg=${OPTARG};;

        esac
done

current=$PWD

echo "Deploy Front & Backend to OpenShift"
if [ "$token" != "" ]; then
   oc login $api --token=$token
else
   echo "oc login $api -u $user -p $password"
   oc login $api -u $user -p $password
fi

REL=$version
echo "Version : $REL"
echo "Backend : $backendurl"

# sed -e "s/VERSION/Dummy/g" -e "s/ORG\//obsidian-tester\//g" ./templates/backend.yml > ./templates/backend-dummy.yml
# sed -e "s/VERSION/Dummy/g" -e "s/GENERATOR_URL/http:\/\/backend-generator-obsidian-dummy.172.28.128.4.xip.io /g" -e "s/ORG\//obsidian-tester\//g" ./templates/front.yml > ./templates/front-dummy.yml

# Change version
sed -e "s/VERSION/$REL/g" -e "s/ORG\//$githuborg/g" ./templates/backend.yml > ./templates/backend-$REL.yml
sed -e "s/VERSION/$REL/g" -e "s/GENERATOR_URL/http:\/\/$backendurl/g" -e "s/ORG\//$githuborg\//g" ./templates/front.yml > ./templates/front-$REL.yml

#
# Remove first 6 chars otherwise OpenShift will complaints --> metadata.name: must match the regex [a-z0-9]([-a-z0-9]*[a-z0-9])? (e.g. 'my-name' or '123-abc')
#
suffix=${REL:6}
suffix_lower=$(echo $suffix | tr '[:upper:]' '[:lower:]')

# Create project
oc new-project obsidian-$suffix_lower
#sleep 5

echo Press any key to create OpenShift Project and deploy ...
read junk

# Deploy the backend
echo "Deploy the backend ..."
oc create -f ./templates/backend-$REL.yml
oc process backend-generator-s2i | oc create -f -
oc start-build backend-generator-s2i

# Deploy the Front
echo "Deploy the frontend ..."
oc create -f templates/front-$REL.yml
oc process front-generator-s2i | oc create -f -
oc start-build front-generator-s2i


