#!/bin/sh 

HOSTNAMEORIP=$1
PROJECTNAME=${2:-myproject}
GITHUB_USER=$3
GITHUB_TOKEN=$4
CONSOLE_URL=$(minishift console --url)

echo "Project : $PROJECTNAME"
