#!/usr/bin/env bash

# Example :
# Token                         --> ./release-openshift.sh -a api.engint.openshift.com -t xxxxxxxxxxxx -v 1.0.0.Alpha1 -o obsidian-toaster
# User/password (CI Server)     --> ./release-openshift.sh -a 172.16.50.40:8443 -u admin -p admin  -v 1.0.0.Alpha1 -o obsidian-toaster
# User/password (local vagrant) --> ./release-openshift.sh -a 172.28.128.4:8443 -u admin -p admin -v 1.0.0.Dummy \
#                                                          -b http://backend-generator-obsidian-dummy.172.28.128.4.xip.io/ \
#                                                          -o obsidian-tester \
#                                                          -c http://nexus-infra.172.28.128.4.xip.io/content/repositories/releases/org/obsidiantoaster/archetypes-catalog/1.0.0.Dummy/archetypes-catalog-1.0.0.Dummy-archetype-catalog.xml \
#                                                          -n http://nexus-infra.172.28.128.4.xip.io
#
# Example to release Alpha2 of Obsidian on engint.openshift.com machine using the Jboss Nexus Server
#
# ./release-openshift.sh -a api.engint.openshift.com -t xxxxxxxxxxxxxxxxxxxxxx \
#                        -v 1.0.0.Alpha2 \
#                        -b http://backend-generator-obsidian-snapshot.e8ca.engint.openshiftapps.com/ \
#                        -o obsidian-toaster \
#                        -c 'https://repository.jboss.org/nexus/service/local/artifact/maven/redirect?r=releases\&g=org.obsidiantoaster\&a=archetypes-catalog\&v=1.0.0.Alpha2\&e=xml\&c=archetype-catalog' \
#                        -n http://repository.jboss.org/nexus

while getopts a:t:u:p:v:b:o:c:n: option
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
                c) archetypecatalog=${OPTARG};;
                n) mavenserver=${OPTARG};;

        esac
done

current=$PWD

echo "============================="
echo "Log on to the OpenShift server"
echo "============================="
if [ "$token" != "" ]; then
   oc login $api --token=$token
else
   echo "oc login https://$api:8443 -u $user -p $password"
   oc login https://$api:8443 -u $user -p $password
fi

REL=$version
mavenmirrorurl=$mavensever/content/repositories/releases
echo "Version : $REL"
echo "Backend : $backendurl"
echo "Github Org : $githuborg"
echo "Catalog URL : $archetypecatalog"
echo "Maven Server : $mavenserver"
echo "Maven Mirror URL : $mavenmirrorurl"
echo "============================="

# Change version
sed -e "s/VERSION/$REL/g" -e "s/ORG\//$githuborg\//g" -e "s|MAVENSERVER|$mavenserver|g" -e "s|MAVENMIRRORURL|$mavenmirrorurl|g" -e "s|ARCHETYPECATALOG|$archetypecatalog|g" ./templates/backend.yml > ./templates/backend-$REL.yml
sed -e "s/VERSION/$REL/g" -e "s|GENERATOR_URL|$backendurl|g" -e "s/ORG\//$githuborg\//g" ./templates/front.yml > ./templates/front-$REL.yml

#
# Remove first 6 chars otherwise OpenShift will complain --> metadata.name: must match the regex [a-z0-9]([-a-z0-9]*[a-z0-9])? (e.g. 'my-name' or '123-abc')
#
suffix=${REL:6}
suffix_lower=$(echo $suffix | tr '[:upper:]' '[:lower:]')

echo Press any key to create OpenShift Project and deploy ...
read junk

# Create project
echo "============================="
echo "Create Openshift namespace : obsidian-$suffix_lower"
echo "============================="

oc new-project obsidian-$suffix_lower
sleep 5

# Deploy the backend
echo "============================="
echo "Deploy the backend template"
echo "============================="
oc create -f ./templates/backend-$REL.yml
oc process backend-generator-s2i | oc create -f -
oc start-build backend-generator-s2i

# Deploy the Front
echo "============================="
echo "Deploy the frontend ..."
echo "============================="
oc create -f templates/front-$REL.yml
oc process front-generator-s2i | oc create -f -
oc start-build front-generator-s2i


