#!/bin/sh 

$HOSTNAMEORIP=$1
$PROJECTNAME=myproject
$GITHUB_USER=$2
$GITHUB_TOKEN=$3

# Log on to the platform using system:admin user
oc login -u system:admin
oc project $PROJECTNAME

# Install the launchpad-missioncontrol template
oc create -n $PROJECTNAME -f https://raw.githubusercontent.com/openshiftio/launchpad-templates/v2/openshift/launchpad-template.yaml

# Replace edit role with admin in order to allow the jenkins serviceaccount to by example create rolebindings, ...
oc patch template/jenkins-ephemeral -n openshift --type='json' -p='[{"op": "replace", "path": "/objects/3/roleRef/name", "value":"admin"}]'

# Deploy launchpad using your Google account, token
oc new-app launchpad -n openshift \
    -p LAUNCHPAD_MISSIONCONTROL_GITHUB_USERNAME=$GITHUB_USER \
    -p LAUNCHPAD_MISSIONCONTROL_GITHUB_TOKEN=$GITHUB_TOKEN \
    -p LAUNCHPAD_MISSIONCONTROL_OPENSHIFT_CONSOLE_URL=https://$HOSTNAMEORIP:8443 \
    # -p LAUNCHPAD_KEYCLOAK_URL=https://sso.prod-preview.openshift.io/auth \
    # -p LAUNCHPAD_KEYCLOAK_REALM=fabric8 \
    -p LAUNCHPAD_KEYCLOAK_URL= \
    -p LAUNCHPAD_KEYCLOAK_REALM= \
    # -p LAUNCHPAD_MISSIONCONTROL_OPENSHIFT_API_URL=https://openshift.default.svc.cluster.local
    -p LAUNCHPAD_MISSIONCONTROL_OPENSHIFT_USERNAME=developer \
    -p LAUNCHPAD_MISSIONCONTROL_OPENSHIFT_PASSWORD= \
    -p LAUNCHPAD_BACKEND_CATALOG_GIT_REPOSITORY=https://github.com/openshiftio/booster-catalog.git \
    -p LAUNCHPAD_BACKEND_CATALOG_GIT_REF=master \
    -p LAUNCHPAD_BACKEND_CATALOG_INDEX_PERIOD="0" \
    # -p LAUNCHPAD_BACKEND_URL=http://launchpad-backend-$PROJECTNAME.$HOSTNAMEORIP.nip.io
    -p LAUNCHPAD_BACKEND_URL=http://launchpad-backend-$PROJECTNAME.$HOSTNAMEORIP.nip.io
