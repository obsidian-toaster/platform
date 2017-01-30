#!/usr/bin/env bash

: ${1:?"Organisation where repo will be forked."}
: ${2:?"Delete forked repo first"}

ORG=$1
TO_BE_DELETED=$2

read -p "Enter Github Username/account: " USERNAME
read -s -p "Enter Password: " PASSWORD

echo "$USERNAME : $PASSWORD"

githubPlatformRepos=(
"platform" \
"obsidian-addon"  \
"generator-backend"  \
"generator-frontend" \
"obsidian-toaster.github.io"
)

JSONFILE=quickstarts.json
START=0
END=$(jq '. | length' $JSONFILE)

if [ $TO_BE_DELETED = true ]; then
  for repo in "${githubPlatformRepos[@]}"
  do
    echo "Platform Forked repo to be deleted : https://api.github.com/repos/$ORG/obsidian-toaster-quickstarts/$repo"
    curl -u $USERNAME:$PASSWORD -X DELETE https://api.github.com/repos/$ORG/$repo
  done

  # Delete QuickStarts as defined within the JSON file
  for ((c=$START;c<=$END-1; c++ ))
  do
	  name=$(jq -r '.['$c'].name' $JSONFILE)
    echo "QuickStarts Forked repo to be deleted : https://api.github.com/repos/$ORG/obsidian-toaster-quickstarts/$name"
    curl -u $USERNAME:$PASSWORD -X DELETE https://api.github.com/repos/$ORG/$name
  done
fi

sleep 5

for repo in "${githubPlatformRepos[@]}"
do
  echo "Platform repo to be git cloned : $repo"
  curl -u $USERNAME:$PASSWORD -X POST https://api.github.com/repos/obsidian-toaster/$repo/forks?org=$ORG
done

for ((c=$START;c<=$END-1; c++ ))
do
  name=$(jq -r '.['$c'].name' $JSONFILE)
  echo "QuickStart to be git cloned : $name"
  curl -u $USERNAME:$PASSWORD -X POST https://api.github.com/repos/obsidian-toaster-quickstarts/$name/forks?org=$ORG
done
