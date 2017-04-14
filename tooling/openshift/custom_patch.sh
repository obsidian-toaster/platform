#!/usr/bin/env bash 

#
# Install Launchpad mission control within an openshift template using the parameters passed
# Patch jenkins to use admin as role
# bash <(curl -sL https://goo.gl/1XEYNb) hostIP projectName myGithubToken username:password 
# example : bash <(curl -sL https://goo.gl/1XEYNb) 192.168.64.25 test1 cmoulliard mygithubtoken developer:developer
#
HOSTNAMEORIP=$1
PROJECTNAME=${2:-myproject}
GITHUB_USER=$3
GITHUB_TOKEN=$4
CONSOLE_URL=$(minishift console --url)
IFS=':' read -a IDENTITY <<< "$5"

echo "Host: $HOSTNAMEORIP"
echo "Project: $PROJECTNAME"
echo "Console: $CONSOLE_URL"
echo "Github user: $GITHUB_USER"
echo "Identity: ${IDENTITY[0]}, ${IDENTITY[1]}"

oc login -u ${IDENTITY[0]} -p ${IDENTITY[1]}
oc new-project $PROJECTNAME

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
    -p LAUNCHPAD_MISSIONCONTROL_OPENSHIFT_USERNAME=$IDENTITY[0] \
    -p LAUNCHPAD_MISSIONCONTROL_OPENSHIFT_PASSWORD=$IDENTITY[1] \
    -p LAUNCHPAD_BACKEND_CATALOG_GIT_REPOSITORY=https://github.com/openshiftio/booster-catalog.git \
    -p LAUNCHPAD_BACKEND_CATALOG_GIT_REF=master \
    -p LAUNCHPAD_BACKEND_CATALOG_INDEX_PERIOD="0" \
    -p LAUNCHPAD_FRONTEND_HOST=launchpad-frontend-$PROJECTNAME.$HOSTNAMEORIP.nip.io

# Replace edit role with admin in order to allow the jenkins serviceaccount to by example create rolebindings, ...
# Log on to the platform using system:admin user
oc login -u system:admin
oc patch template/jenkins-ephemeral -n openshift --type='json' -p='[{"op": "replace", "path": "/objects/3/roleRef/name", "value":"admin"}]'
