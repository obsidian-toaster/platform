
# Front Generator

## OpenShift 

To deploy this project on OpenShift, verify that an OpenShift instance is available or setup one locally
using minishift

```
minishift delete
minishift start --deploy-router=true --openshift-version=v1.3.1
oc login --username=admin --password=admin
eval $(minishift docker-env)
```

To create our Obsidian Front UI OpenShift application, we will deploy an OpenShift template which
contains the required objects; service, route, BuildConfig & Deployment config. The docker image 
used is registry.access.redhat.com/rhscl/nginx-18-rhel7 which exposes a HTTP Server.

To install the template and create a new application, use these commands

```
oc new-project front
oc create -f templates/template_s2i.yml
oc process front-generator-s2i | oc create -f -
oc start-build front-generator
```

Remark: In order to change the address of the backend that you will use on OpenShift, change the `forge_url` value defined within the file src/assets/settings.json and commit the change. 

You can now access the backend using its route

```
curl http://$(oc get routes | grep front-generator | awk '{print $2}')/index.html
```

Remarks:

* For every new commit about this project `front-generator` that you want to test after the initial installation of the template, launching a new build
  on OpenShift is just required `oc start-build front-generator`

* If for any reasons, you would like to redeploy a new template, then you should first delete the template and the corresponding objects

```
oc delete is/front-generator
oc delete bc/front-generator
oc delete dc/front-generator
oc delete svc/front-generator
oc delete route/front-generator
oc delete template/front-generator
oc create -f templates/template_s2i.yml
oc process front-generator-s2i | oc create -f -
oc start-build front-generator
```

# S2i Scripts

The S2I scripts, packaged within this project allow to override the scripts used within the S2I Build Image. They have been created
as the build image will only execute the `npm install` during the assemby phase and `npm start` during the run phase.

As our process requires 2 installations instructions, the scripts have been customized

They can be tested locally using the [s2i tool](https://github.com/openshift/source-to-image) and this command

```
s2i build . ryanj/centos7-s2i-nodejs:current my-nodejs -c
```

# Backend

To deploy the backend generator on OpenShift, run this command within the terminal

```
oc new-project backend
oc create -f templates/backend-template.yml
oc process backend-generator-s2i | oc create -f -
oc start-build generator-backend-s2i
```

Redeploy the application with:

```
mvn fabric8:deploy -Popenshift
```

You can verify now that the service replies

```
http $(minishift service generator-backend --url=true)/forge/version
curl $(minishift service generator-backend --url=true)/forge/version
```
