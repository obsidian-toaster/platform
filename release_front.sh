#!/bin/bash

REL="1.0.0.Alpha1"
REL_NODE="1.0.0-Alpha1"
FORGE_URL="http://generator-backend-obsidian-alpha1.e8ca.engint.openshiftapps.com/forge"

cd $TMPDIR
rm -rf generator-frontend
git clone https://github.com/obsidian-toaster/generator-frontend.git
cd generator-frontend
npm install package-json-io
node -e "var pkg = require('package-json-io'); pkg.read(function(err, data) { data.version = '$REL_NODE'; pkg.update(data, function(){}); })"
git commit -a -m "Released $REL of generator-frontend"
git clone https://github.com/obsidian-toaster/obsidian-toaster.github.io.git build
cd build
git checkout -b "$REL"
rm -rf *
cd -
npm install
npm run build:prod
cp -r dist/* build
cd build
ls -la
git add .
git commit -a -m "Released $REL of generator-frontend"
git push origin "$REL"

cd -

git tag "$REL"
git push origin --tags