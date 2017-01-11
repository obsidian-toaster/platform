#!/usr/bin/env bash

set -e

# HOST_IP="172.16.50.40" # CI Widlfy Swarm
HOST_IP="172.28.128.4" # Local Vagrant

OPENSHIFT_DIR=/opt/openshift-origin-v1.4
TEMP_DIR=/home/tmp
rm -rf $TEMP_DIR && mkdir -p $TEMP_DIR
rm -rf $OPENSHIFT_DIR && mkdir -p $OPENSHIFT_DIR
ifup eth0

echo "===================================================="
echo "Install Yum packages"
echo "===================================================="
cat > /etc/yum.repos.d/docker.repo << __EOF__
[docker]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
__EOF__

yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion docker-engine
yum -y update

echo "===================================================="
echo "Install OpenShift Client"
echo "===================================================="
URL=https://github.com/openshift/origin/releases/download/v1.4.0-rc1/openshift-origin-client-tools-v1.4.0-rc1.b4e0954-linux-64bit.tar.gz
OC_CLIENT_FILE=openshift-origin-client-tools-v1.4.0-rc1
cd $TEMP_DIR && mkdir $OC_CLIENT_FILE && cd $OC_CLIENT_FILE
wget -q $URL
tar -zxf openshift-origin-client-*.tar.gz --strip-components=1 && cp oc /usr/local/bin

echo "Add Docker service and launch it"
mkdir -p /etc/systemd/system/docker.service.d

cat > /etc/systemd/system/docker.service.d/override.conf << __EOF__
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon --storage-driver=overlay --insecure-registry 172.30.0.0/16
__EOF__

systemctl daemon-reload
systemctl enable docker

systemctl restart docker

echo "===================================================="
echo "Get OpenShift Binaries"
echo "===================================================="
OPENSHIFT_URL=https://github.com/openshift/origin/releases/download/v1.4.0-rc1/openshift-origin-server-v1.4.0-rc1.b4e0954-linux-64bit.tar.gz
mkdir $OPENSHIFT_DIR && chmod 755 /opt $OPENSHIFT_DIR && cd $OPENSHIFT_DIR
wget -q $OPENSHIFT_URL
tar -zxvf openshift-origin-server-*.tar.gz --strip-components 1
rm -f openshift-origin-server-*.tar.gz

echo "===================================================="
echo "Set and load environments"
echo "===================================================="
cat > /etc/profile.d/openshift.sh << __EOF__
export OPENSHIFT=/opt/openshift-origin-v1.4
export OPENSHIFT_VERSION=v1.4.0-rc1
export PATH=$OPENSHIFT:$PATH
export KUBECONFIG=$OPENSHIFT/openshift.local.config/master/admin.kubeconfig
export CURL_CA_BUNDLE=$OPENSHIFT/openshift.local.config/master/ca.crt
__EOF__
chmod 755 /etc/profile.d/openshift.sh
. /etc/profile.d/openshift.sh

echo "===================================================="
echo "Prefetch docker images"
echo "===================================================="
docker pull openshift/origin-pod:$OPENSHIFT_VERSION
docker pull openshift/origin-sti-builder:$OPENSHIFT_VERSION
docker pull openshift/origin-docker-builder:$OPENSHIFT_VERSION
docker pull openshift/origin-deployer:$OPENSHIFT_VERSION
docker pull openshift/origin-docker-registry:$OPENSHIFT_VERSION
docker pull openshift/origin-haproxy-router:$OPENSHIFT_VERSION

echo "===================================================="
echo "Generate OpenShift V3 configuration files"
echo "===================================================="
./openshift start --master=$HOST_IP --cors-allowed-origins=.* --hostname=$HOST_IP --write-config=openshift.local.config
chmod +r $OPENSHIFT/openshift.local.config/master/admin.kubeconfig
chmod +r $OPENSHIFT/openshift.local.config/master/openshift-registry.kubeconfig
chmod +r $OPENSHIFT/openshift.local.config/master/openshift-router.kubeconfig

echo "===================================================="
echo "Change default domain"
echo "===================================================="
sed -i "s/router.default.svc.cluster.local/$HOST_IP.xip.io/" $OPENSHIFT/openshift.local.config/master/master-config.yaml

echo "===================================================="
echo "Configure Openshift service & launch it"
echo "===================================================="
cat > /etc/systemd/system/openshift-origin.service << __EOF__
[Unit]
Description=Origin Service
After=docker.service
Requires=docker.service

[Service]
Restart=always
RestartSec=10s
ExecStart=/opt/openshift-origin-v1.4/openshift start --public-master=https://$HOST_IP:8443 --master-config=/opt/openshift-origin-v1.4/openshift.local.config/master/master-config.yaml --node-config=/opt/openshift-origin-v1.4/openshift.local.config/node-$HOST_IP/node-config.yaml
WorkingDirectory=/opt/openshift-origin-v1.4

[Install]
WantedBy=multi-user.target
__EOF__

systemctl daemon-reload
systemctl enable openshift-origin
systemctl start openshift-origin

echo "===================================================="
echo "Create admin account"
echo "===================================================="
oc login -u system:admin
oc adm policy add-cluster-role-to-user cluster-admin admin
oc login -u admin -p admin

echo "===================================================="
echo "Create Registry"
echo "===================================================="
mkdir /opt/openshift-registry
chcon -Rt svirt_sandbox_file_t /opt/openshift-registry
chown 1001.root /opt/openshift-registry
oc adm policy add-scc-to-user privileged system:serviceaccount:default:registry
oc adm registry --service-account=registry --config=/opt/openshift-origin-v1.4/openshift.local.config/master/admin.kubeconfig --mount-host=/opt/openshift-registry

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
cd ~
git clone https://github.com/openshift/openshift-ansible.git
cd openshift-ansible/roles/openshift_examples/files/examples/latest/
for f in image-streams/image-streams-centos7.json; do cat $f | oc create -n openshift -f -; done
for f in db-templates/*.json; do cat $f | oc create -n openshift -f -; done
for f in quickstart-templates/*.json; do cat $f | oc create -n openshift -f -; done

echo "===================================================="
echo "Add external nameserver"
echo "===================================================="
cat >> /etc/resolv.conf << __EOF__
nameserver 8.8.8.8
__EOF__
service docker restart