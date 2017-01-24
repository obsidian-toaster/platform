#!/usr/bin/env bash

set -e

TEMP_DIR=/home/tmp
rm -rf $TEMP_DIR/openshift-ansible

OPENSHIFT_DIR=/opt/openshift-origin-v1.4

. /etc/profile.d/openshift.sh

echo "====== Wait till OpenShift is started & replies to http request on port 8443 ======"
while true; do
  curl -k -s -f -o /dev/null --connect-timeout 1 https://localhost:8443/healthz/ready && break || sleep 1
done

echo "===================================================="
echo "Create admin account"
echo "===================================================="
oc login -u system:admin
oc adm policy add-cluster-role-to-user cluster-admin admin
oc login -u admin -p admin

echo "===================================================="
echo "Create Registry"
echo "===================================================="
chcon -Rt svirt_sandbox_file_t /opt/openshift-registry
chown 1001.root /opt/openshift-registry
oc adm policy add-scc-to-user privileged system:serviceaccount:default:registry
oc adm registry --service-account=registry --config=$OPENSHIFT_DIR/openshift.local.config/master/admin.kubeconfig --mount-host=/opt/openshift-registry

echo "===================================================="
echo "Create Router"
echo "===================================================="
oc adm policy add-scc-to-user hostnetwork -z router
oc adm policy add-scc-to-user hostnetwork system:serviceaccount:default:router
oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:default:router
oc adm router router --replicas=1 --service-account=router

echo "===================================================="
echo "Install Default images"
echo "===================================================="
cd $TEMP_DIR
git clone https://github.com/openshift/openshift-ansible.git
cd openshift-ansible/roles/openshift_examples/files/examples/latest/
for f in image-streams/image-streams-centos7.json; do cat $f | oc create -n openshift -f -; done
for f in db-templates/*.json; do cat $f | oc create -n openshift -f -; done
for f in quickstart-templates/*.json; do cat $f | oc create -n openshift -f -; done
