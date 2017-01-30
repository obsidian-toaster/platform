#!/usr/bin/env bash

: ${1:?"Organisation where repo will be forked."}
: ${2:?"Delete forked repo first"}

ORG=$1
TO_BE_DELETED=$2

read -p "Enter Github Username/account: " USERNAME
read -s -p "Enter Password: " PASSWORD

echo "$USERNAME : $PASSWORD"

githubRepos=(
"obsidian-toaster-quickstarts/rest_vertx" \
"obsidian-toaster-quickstarts/rest_springboot-tomcat"  \
"obsidian-toaster-quickstarts/secured_rest-springboot"  \
"obsidian-toaster-quickstarts/rest_wildfly-swarm" \
"obsidian-toaster/platform"  \
"obsidian-toaster/obsidian-addon"  \
"obsidian-toaster/generator-backend"  \
"obsidian-toaster/generator-frontend" \
"obsidian-toaster/obsidian-toaster.github.io"
)

for repo in "${githubRepos[@]}"
do
   if [ $TO_BE_DELETED = true ]; then
      IFS='/' read -r -a array <<< "$repo"
      echo "Forked repo to be deleted : ${array[1]}"
      curl -u $USERNAME:$PASSWORD -X DELETE https://api.github.com/repos/$ORG/$repo
   fi
done

sleep 5
for repo in "${githubRepos[@]}"
do
   echo "Fork repo : $repo"
   curl -u $USERNAME:$PASSWORD -X POST https://api.github.com/repos/$repo/forks?org=$ORG
done
