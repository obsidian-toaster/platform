#!/usr/bin/env bash

# Author  : Charles Moulliard
# Date    : 12-Jan-2017
# Version : 1.1

set -e

HOST_IP=${1:-172.28.128.4} # Host IP

echo "===================================================="
echo "IP Address to be used : $HOST_IP"
echo "===================================================="

echo "===================================================="
echo "Setup variables"
echo "===================================================="
OPENSHIFT_DIR=/opt/openshift-origin-v1.4
OPENSHIFT=/opt/openshift-origin-v1.4

# OPENSHIFT_VERSION=v1.4.0-rc1
# OC_CLIENT_FILE=openshift-origin-client-tools-v1.4.0-rc1
# OC_URL=https://github.com/openshift/origin/releases/download/v1.4.0-rc1/openshift-origin-client-tools-v1.4.0-rc1.b4e0954-linux-64bit.tar.gz
# OPENSHIFT_URL=https://github.com/openshift/origin/releases/download/v1.4.0-rc1/openshift-origin-server-v1.4.0-rc1.b4e0954-linux-64bit.tar.gz

OPENSHIFT_VERSION=v1.4.1
OC_CLIENT_FILE=openshift-origin-client-tools-v1.4.1
OC_URL=https://github.com/openshift/origin/releases/download/v1.4.1/openshift-origin-client-tools-v1.4.1-3f9807a-linux-64bit.tar.gz
OPENSHIFT_URL=https://github.com/openshift/origin/releases/download/v1.4.1/openshift-origin-server-v1.4.1-3f9807a-linux-64bit.tar.gz

TEMP_DIR=/home/tmp
REGISTRY_DIR=/opt/openshift-registry
DOCKER_SERVICE=/etc/systemd/system/docker.service.d

echo "===================================================="
echo "Clean directories & create them"
echo "===================================================="
rm -rf {$TEMP_DIR,$TEMP_DIR/openshift-ansible,$OPENSHIFT_DIR/openshift.local.config,$OPENSHIFT_DIR/openshift.local.etcd,$REGISTRY_DIR,$DOCKER_SERVICE} && mkdir -p {$TEMP_DIR,$OPENSHIFT_DIR,$REGISTRY_DIR,$DOCKER_SERVICE}
chmod 755 /opt $OPENSHIFT_DIR

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

yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion docker-engine socat
yum -y update

echo "===================================================="
echo "Install OpenShift Client"
echo "===================================================="
cd $TEMP_DIR && mkdir $OC_CLIENT_FILE && cd $OC_CLIENT_FILE
curl -kOL $OC_URL
tar -zxf openshift-origin-client-*.tar.gz --strip-components=1 && cp oc /usr/local/bin

echo "===================================================="
echo "Add Docker service and launch it"
echo "===================================================="
cat > $DOCKER_SERVICE/override.conf << __EOF__
[Service]
ExecStart=
ExecStart=/usr/bin/docker daemon -s devicemapper --insecure-registry 172.30.0.0/16
# TODO : -H unix:// -H tcp://0.0.0.0:2376 --tlsverify --tlscacert=/var/lib/boot2docker/ca.pem --tlscert=/var/lib/boot2docker/server.pem --tlskey=/var/lib/boot2docker/server-key.pem
__EOF__

systemctl daemon-reload
systemctl enable docker
systemctl restart docker

echo "===================================================="
echo "Get OpenShift Binaries"
echo "===================================================="
cd $OPENSHIFT_DIR && curl -kOL $OPENSHIFT_URL
tar -zxvf openshift-origin-server-*.tar.gz --strip-components=1
rm -f openshift-origin-server-*.tar.gz

echo "===================================================="
echo "Set and load environments"
echo "===================================================="
cat > /etc/profile.d/openshift.sh << __EOF__
export OPENSHIFT=$OPENSHIFT
export OPENSHIFT_VERSION=$OPENSHIFT_VERSION
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

if [ "$host_ip" != "172.28.128.4" ]; then
  echo "===================================================="
  echo "Start Eth1 device - required since vagrant 1.9.1"
  echo "===================================================="
  ifup eth1
fi

echo "===================================================="
echo "Generate OpenShift V3 configuration files"
echo "===================================================="
$OPENSHIFT/openshift start --master=$HOST_IP --cors-allowed-origins=.* --hostname=$HOST_IP --write-config=openshift.local.config
chmod +r $OPENSHIFT/openshift.local.config/master/admin.kubeconfig
chmod +r $OPENSHIFT/openshift.local.config/master/openshift-registry.kubeconfig
chmod +r $OPENSHIFT/openshift.local.config/master/openshift-router.kubeconfig

echo "===================================================="
echo "Change default domain and replace 0.0.0.0 with the IP address"
echo "===================================================="
sed -i "s/router.default.svc.cluster.local/$HOST_IP.xip.io/" $OPENSHIFT/openshift.local.config/master/master-config.yaml

echo "===================================================="
echo "Stop/Disable Firewall"
echo "===================================================="
chkconfig iptables off
systemctl disable firewalld
systemctl stop firewalld

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
echo "Add external nameserver & restart docker"
echo "===================================================="
echo 'nameserver 8.8.8.8' >>  /etc/resolv.conf
service docker restart


# . /etc/profile.d/openshift.sh

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

