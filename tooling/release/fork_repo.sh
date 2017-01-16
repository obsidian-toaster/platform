#!/usr/bin/env bash

: ${1:?"Must specify a github username."}
: ${2:?"Must specify the password"}
: ${3:?"Organisation where repo will be forked."}
: ${4:?"Delete forked repo first"}

USERNAME=$1
PASSWORD=$2
ORG=$3
TO_BE_DELETED=$4

githubRepos=("obsidian-toaster-quickstarts/quick_rest_vertx" \
"obsidian-toaster-quickstarts/quick_rest_springboot-tomcat"  \
"obsidian-toaster-quickstarts/quick_secured_rest-springboot"  \
"obsidian-toaster/platform"  \
"obsidian-toaster/obsidian-addon"  \
"obsidian-toaster/generator-backend"  \
"obsidian-toaster/generator-frontend" \
"obsidian-toaster/obsidian-toaster.github.io")

githubReposForked=("quick_rest_vertx" \
"quick_rest_springboot-tomcat"  \
"quick_secured_rest-springboot"  \
"platform"  \
"obsidian-addon"  \
"generator-backend" \
"generator-frontend" \
"obsidian-toaster.github.io")

for repo in "${githubReposForked[@]}"
do
   if [ $TO_BE_DELETED = true ]; then
      echo "Forked repo to be deleted : $repo"
      curl -u $USERNAME:$PASSWORD -X DELETE https://api.github.com/repos/$ORG/$repo
   fi
done

sleep 5
echo Press any key to fork the repos
read junk
for repo in "${githubRepos[@]}"
do
   #echo "curl -u $USERNAME:$PASSWORD -X POST https://api.github.com/repos/$repo/forks?org=$ORG"
   curl -u $USERNAME:$PASSWORD -X POST https://api.github.com/repos/$repo/forks?org=$ORG
done
