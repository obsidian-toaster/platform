#!/usr/bin/env bash 

HOSTNAMEORIP=$1
PROJECTNAME=${2:-myproject}
GITHUB_USER=$3
GITHUB_TOKEN=$4
CONSOLE_URL=$(minishift console --url)

echo "Host: $HOSTNAMEORIP"
echo "Project: $PROJECTNAME"
echo "Console: $CONSOLE_URL"
echo "Github user: $GITHUB_USER"

# Log on to the platform using system:admin user
oc login -u system:admin
oc project $PROJECTNAME

# Install the launchpad-missioncontrol template
oc create -n $PROJECTNAME -f https://raw.githubusercontent.com/openshiftio/launchpad-templates/v2/openshift/launchpad-template.yaml

# Local Deployment of  launchpad 
# -p LAUNCHPAD_MISSIONCONTROL_OPENSHIFT_API_URL=https://openshift.default.svc.cluster.local
# -p LAUNCHPAD_KEYCLOAK_URL=https://sso.prod-preview.openshift.io/auth \
# -p LAUNCHPAD_KEYCLOAK_REALM=fabric8 \
oc new-app launchpad -n $PROJECTNAME \
    -p LAUNCHPAD_MISSIONCONTROL_GITHUB_USERNAME=$GITHUB_USER \
    -p LAUNCHPAD_MISSIONCONTROL_GITHUB_TOKEN=$GITHUB_TOKEN \
    -p LAUNCHPAD_MISSIONCONTROL_OPENSHIFT_CONSOLE_URL=$CONSOLE_URL \
    -p LAUNCHPAD_MISSIONCONTROL_OPENSHIFT_API_URL=$CONSOLE_URL \
    -p LAUNCHPAD_KEYCLOAK_URL= \
    -p LAUNCHPAD_KEYCLOAK_REALM= \
    -p LAUNCHPAD_MISSIONCONTROL_OPENSHIFT_USERNAME=developer \
    -p LAUNCHPAD_MISSIONCONTROL_OPENSHIFT_PASSWORD= \
    -p LAUNCHPAD_BACKEND_CATALOG_GIT_REPOSITORY=https://github.com/openshiftio/booster-catalog.git \
    -p LAUNCHPAD_BACKEND_CATALOG_GIT_REF=master \
    -p LAUNCHPAD_BACKEND_CATALOG_INDEX_PERIOD="0" \
    -p LAUNCHPAD_FRONTEND_HOST=launchpad-frontend-$PROJECTNAME.$HOSTNAMEORIP.nip.io

# Replace edit role with admin in order to allow the jenkins serviceaccount to by example create rolebindings, ...
oc patch template/jenkins-ephemeral -n openshift --type='json' -p='[{"op": "replace", "path": "/objects/3/roleRef/name", "value":"admin"}]'
