# Deploy locally OpenShift using Vagrant & Virtualbox

The procedure described within this document can also be used to setup on MacOS a VM using Virtualbox & Vagrant. The following steps describe how to
to create a new VM running Centos 7.1, provision the machine with OpenShift.

Version of Vagrant used 1.8.7 which has been installed using brew :
 
`https://raw.githubusercontent.com/johnjelinek/homebrew-cask/7f9e37e23d7c6c394cb838ea408b05e4c803f41f/Casks/vagrant.rb`

Remark: The eth1 card/device added is nit restarted automatically after a `vagrant halt and vagrant up` using version 1.9.1 of vagrant. This is why I recommend
to continue to use this older version

Next, install vagrant landrush plugin

```
vagrant plugin install landrush
```

and the project

```
git clone https://github.com/obsidian-toaster/platform.git
cd obsidian-toaster/platform/tooling/openshift
vagrant up --provider virtualbox
```

# Deploy OpenShift using Minishift

Minishift is a Go Application which has been created from Minikube project of Kubernetes. It extends the features proposed by the Kubernetes client to package/Deploy
OpenShift within a VM machine. Different hypervisors are supported as Virtualbox, xhyve & VMWare. You can find more information about Minishift like also how to intall from the project:
https://github.com/minishift/minishift

To install the required environment which support the Obsidian quickstarts, it is recommended to pass the following parameters when you will request to minishift to start a new VM.

```
minishift start --openshift-version=v1.4.1 --memory=4000 --vm-driver=virtualbox --iso-url=https://github.com/minishift/minishift-centos-iso/releases/download/v1.0.0-rc.1/minishift-centos.iso --docker-env=[storage-driver=devicemapper]
```

Version of Minishift to be used is >= 1.0.0.Beta2

# Steps required to install & configure OpenShift manually

##  Install Yum packages
```
cat > /etc/yum.repos.d/docker.repo << '__EOF__'
[docker]
name=Docker Repository
baseurl=https://yum.dockerproject.org/repo/main/centos/7/
enabled=1
gpgcheck=1
gpgkey=https://yum.dockerproject.org/gpg
__EOF__
 
yum -y install wget git net-tools bind-utils iptables-services bridge-utils bash-completion docker-engine
yum -y update
```

##  Install OpenShift oc client
```
URL=https://github.com/openshift/origin/releases/download/v1.4.0-rc1/openshift-origin-client-tools-v1.4.0-rc1.b4e0954-linux-64bit.tar.gz
OC_CLIENT_FILE=openshift-origin-client-tools-v1.4.0-rc1
cd $HOME && mkdir $OC_CLIENT_FILE && cd $OC_CLIENT_FILE 
wget -q $URL
tar -zxf openshift-origin-client-*.tar.gz --strip-components=1 && cp oc /usr/local/bin
```

##  Register Docker Service

```
mkdir -p /etc/systemd/system/docker.service.d 
 
cat > /etc/systemd/system/docker.service.d/override.conf << '__EOF__'
[Service] 
ExecStart= 
ExecStart=/usr/bin/docker daemon --storage-driver=overlay --insecure-registry 172.30.0.0/16
__EOF__
 
systemctl daemon-reload
systemctl enable docker
 
systemctl restart docker
```

##  Get OpenShift Binaries

```
OPENSHIFT_DIR=/opt/openshift-origin-v1.4
OPENSHIFT_URL=https://github.com/openshift/origin/releases/download/v1.4.0-rc1/openshift-origin-server-v1.4.0-rc1.b4e0954-linux-64bit.tar.gz
mkdir $OPENSHIFT_DIR && chmod 755 /opt $OPENSHIFT_DIR && cd $OPENSHIFT_DIR
wget -q $OPENSHIFT_URL
tar -zxvf openshift-origin-server-*.tar.gz --strip-components 1
rm -f openshift-origin-server-*.tar.gz
```

##  Set and load environments

```
cat > /etc/profile.d/openshift.sh << '__EOF__'
export OPENSHIFT=/opt/openshift-origin-v1.4
export OPENSHIFT_VERSION=v1.4.0-rc1
export PATH=$OPENSHIFT:$PATH
export KUBECONFIG=$OPENSHIFT/openshift.local.config/master/admin.kubeconfig
export CURL_CA_BUNDLE=$OPENSHIFT/openshift.local.config/master/ca.crt
__EOF__
chmod 755 /etc/profile.d/openshift.sh
. /etc/profile.d/openshift.sh
```

##  Prefetch Docker images

```
docker pull openshift/origin-pod:$OPENSHIFT_VERSION
docker pull openshift/origin-sti-builder:$OPENSHIFT_VERSION
docker pull openshift/origin-docker-builder:$OPENSHIFT_VERSION
docker pull openshift/origin-deployer:$OPENSHIFT_VERSION
docker pull openshift/origin-docker-registry:$OPENSHIFT_VERSION
docker pull openshift/origin-haproxy-router:$OPENSHIFT_VERSION
```

##  Generate OpenShift V3 configuration files

```
./openshift start --master=172.16.50.40 --cors-allowed-origins=.* --hostname=172.16.50.40 --write-config=openshift.local.config
chmod +r $OPENSHIFT/openshift.local.config/master/admin.kubeconfig
chmod +r $OPENSHIFT/openshift.local.config/master/openshift-registry.kubeconfig
chmod +r $OPENSHIFT/openshift.local.config/master/openshift-router.kubeconfig
```

##  Change the default router subdomain in master-config.yaml

```
sed -i 's|router.default.svc.cluster.local|172.16.50.40.xip.io|' $OPENSHIFT/openshift.local.config/master/master-config.yaml
```

##  Define OpenShift Service & launch it

```
cat > /etc/systemd/system/openshift-origin.service << '__EOF__'
[Unit]
Description=Origin Service
After=docker.service
Requires=docker.service
 
[Service]
Restart=always
RestartSec=10s
ExecStart=/opt/openshift-origin-v1.4/openshift start --public-master=https://172.16.50.40:8443 --master-config=/opt/openshift-origin-v1.4/openshift.local.config/master/master-config.yaml --node-config=/opt/openshift-origin-v1.4/openshift.local.config/node-172.16.50.40/node-config.yaml
WorkingDirectory=/opt/openshift-origin-v1.4
 
[Install]
WantedBy=multi-user.target
 
systemctl daemon-reload
systemctl enable openshift-origin
systemctl start openshift-origin
```

##  Create admin account

```
oc login -u system:admin
oc adm policy add-cluster-role-to-user cluster-admin admin
oc login -u admin -p admin
```

##  Create Registry

```
mkdir /opt/openshift-registry
chcon -Rt svirt_sandbox_file_t /opt/openshift-registry
chown 1001.root /opt/openshift-registry
oc adm policy add-scc-to-user privileged system:serviceaccount:default:registry
oc adm registry --service-account=registry --config=/opt/openshift-origin-v1.4/openshift.local.config/master/admin.kubeconfig --mount-host=/opt/openshift-registry
```

##  Create Router
```
oc adm policy add-scc-to-user hostnetwork -z router
oc adm policy add-scc-to-user hostnetwork system:serviceaccount:default:router
oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:default:router
oc adm router router --replicas=1 --service-account=router
```

##  Install Default images

```
cd ~
git clone https://github.com/openshift/openshift-ansible.git
cd openshift-ansible/roles/openshift_examples/files/examples/latest/
for f in image-streams/image-streams-centos7.json; do cat $f | oc create -n openshift -f -; done
for f in db-templates/*.json; do cat $f | oc create -n openshift -f -; done
for f in quickstart-templates/*.json; do cat $f | oc create -n openshift -f -; done
```

