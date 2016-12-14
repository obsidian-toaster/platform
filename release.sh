#!/bin/bash

if [ -z ${1+x} ];
    then echo "version is not set usage $0 <version e.g. 1.0.0>"; exit 0;
fi

VERSION="$1"

function mvnRelease {
  mvn release:prepare -B -DreleaseVersion=$VERSION
  mvn release:perform
}

git clone https://github.com/obsidian-toaster-quickstarts/quick_rest_vertx.git
cd quick_rest_vertx
mvnRelease
cd -

git clone https://github.com/obsidian-toaster-quickstarts/quick_rest_springboot-tomcat.git
cd quick_rest_springboot-tomcat
mvnRelease
cd -

git clone https://github.com/obsidian-toaster-quickstarts/quick_secured_rest-springboot.git
cd quick_secured_rest-springboot
mvnRelease
cd -

git clone https://github.com/obsidian-toaster/obsidian-addon.git
cd obsidian-addon
mvnRelease
cd -

git clone https://github.com/obsidian-toaster/generator-backend.git
cd generator-backend
mvnRelease
cd -

git clone https://github.com/obsidian-toaster/generator-frontend.git
cd generator-frontend

npm install package-json-io
node -e "var pkg = require('package-json-io'); pkg.read(function(err, data) { data.version = '$VERSION'; pkg.update(data, function(){}); })"
git commit -m "released $VERSION of generator-frontend"
git tag "release-$VERSION"
git push origin --tags
npm publish .

# clean up
rm -rf obsidian-addon quick_rest_springboot-tomcat quick_rest_vertx generator-backend generator-frontend