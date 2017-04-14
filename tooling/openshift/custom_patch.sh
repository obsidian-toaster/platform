#!/bin/sh 

# Log on to the platform using system:admin user
oc login -u system:admin

# Install the launchpad-missioncontrol template
oc create -n openshift -f https://raw.githubusercontent.com/openshiftio/launchpad-templates/v2/openshift/launchpad-template.yaml

# Replace edit role with admin in order to allow the jenkins serviceaccount to by example create rolebindings, ...
oc patch template/jenkins-ephemeral -n openshift --type='json' -p='[{"op": "replace", "path": "/objects/3/roleRef/name", "value":"admin"}]'
