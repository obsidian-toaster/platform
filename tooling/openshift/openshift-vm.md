# Vagrant

The procedure described within this document can also be used to setup on MacOS a VM using Virtualbox & Vagrant. The following steps describe how to
to create a new VM running Centos 7.1, to ssh to the machine and also to provision the machine with OpenShift.

Remarks:
- Some manual steps have been included in order to ssh the vagrant vm using `ssh vagrant@IP_ADDRESS` 
- The eth0 card should also be disabled otherwise OpenShift (for a reason which isn't yet know) will use the NAT address to redirect the user to be authenticated 

```
vagrant destroy -f
rm Vagrantfile
rm -rf .vagrant
cat > Vagrantfile << '**EOF**'

$vmMemory = Integer(ENV['VM_MEMORY'] || 4000)

# Override the default VM name appearing within VirtualBox
$vmName = ENV['VM_NAME'] || "centos7-openshift"

Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  
  # Top level domain
  $tld = "vagrant.ocp"

  config.landrush.enabled = true
  config.landrush.tld = $tld
  config.landrush.guest_redirect_dns = false
  config.landrush.host_ip_address = '172.28.128.4'

  config.vm.network "private_network", ip: "172.28.128.4"
  config.vm.hostname = $tld
  
  config.vm.provider "virtualbox" do |v|
    v.memory = $vmMemory
    v.cpus = 2
    v.name = $vmName
  end
  
  config.vm.provision "shell", path: "/path/to/provision-openshift.sh", keep_color: true

end
**EOF**

vagrant up --provider virtualbox
vagrant ssh

OR

cat > $HOME/.ssh/config << '__EOF__'
Host 172.28.128.4
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    IdentitiesOnly yes
    User vagrant
    IdentityFile $HOME/path/to/.vagrant/machines/default/virtualbox/private_key
    PasswordAuthentication no
__EOF__

ssh vagrant@172.28.128.4
su -
ifdown eth0
sed -i 's|ONBOOT="yes"|ONBOOT="no"|' /etc/sysconfig/network-scripts/ifcfg-eth0 
```

# Install Yum packages
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

# Install OpenShift oc client
```
URL=https://github.com/openshift/origin/releases/download/v1.4.0-rc1/openshift-origin-client-tools-v1.4.0-rc1.b4e0954-linux-64bit.tar.gz
OC_CLIENT_FILE=openshift-origin-client-tools-v1.4.0-rc1
cd $HOME && mkdir $OC_CLIENT_FILE && cd $OC_CLIENT_FILE 
wget -q $URL
tar -zxf openshift-origin-client-*.tar.gz --strip-components=1 && cp oc /usr/local/bin
```

# Register Docker Service

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

# Get OpenShift Binaries

```
OPENSHIFT_DIR=/opt/openshift-origin-v1.4
OPENSHIFT_URL=https://github.com/openshift/origin/releases/download/v1.4.0-rc1/openshift-origin-server-v1.4.0-rc1.b4e0954-linux-64bit.tar.gz
mkdir $OPENSHIFT_DIR && chmod 755 /opt $OPENSHIFT_DIR && cd $OPENSHIFT_DIR
wget -q $OPENSHIFT_URL
tar -zxvf openshift-origin-server-*.tar.gz --strip-components 1
rm -f openshift-origin-server-*.tar.gz
```

# Set and load environments

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

# Prefetch Docker images

```
docker pull openshift/origin-pod:$OPENSHIFT_VERSION
docker pull openshift/origin-sti-builder:$OPENSHIFT_VERSION
docker pull openshift/origin-docker-builder:$OPENSHIFT_VERSION
docker pull openshift/origin-deployer:$OPENSHIFT_VERSION
docker pull openshift/origin-docker-registry:$OPENSHIFT_VERSION
docker pull openshift/origin-haproxy-router:$OPENSHIFT_VERSION
```

# Generate OpenShift V3 configuration files

```
./openshift start --master=172.16.50.40 --cors-allowed-origins=.* --hostname=172.16.50.40 --write-config=openshift.local.config
chmod +r $OPENSHIFT/openshift.local.config/master/admin.kubeconfig
chmod +r $OPENSHIFT/openshift.local.config/master/openshift-registry.kubeconfig
chmod +r $OPENSHIFT/openshift.local.config/master/openshift-router.kubeconfig
```

# Change the default router subdomain in master-config.yaml

```
sed -i 's|router.default.svc.cluster.local|172.16.50.40.xip.io|' $OPENSHIFT/openshift.local.config/master/master-config.yaml
```

# Define OpenShift Service & launch it

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

# Create admin account

```
oc login -u system:admin
oc adm policy add-cluster-role-to-user cluster-admin admin
oc login -u admin -p admin
```

# Create Registry

```
mkdir /opt/openshift-registry
chcon -Rt svirt_sandbox_file_t /opt/openshift-registry
chown 1001.root /opt/openshift-registry
oc adm policy add-scc-to-user privileged system:serviceaccount:default:registry
oc adm registry --service-account=registry --config=/opt/openshift-origin-v1.4/openshift.local.config/master/admin.kubeconfig --mount-host=/opt/openshift-registry
```

# Create Router
```
oc adm policy add-scc-to-user hostnetwork -z router
oc adm policy add-scc-to-user hostnetwork system:serviceaccount:default:router
oc adm policy add-cluster-role-to-user cluster-reader system:serviceaccount:default:router
oc adm router router --replicas=1 --service-account=router
```

# Install Default images

```
cd ~
git clone https://github.com/openshift/openshift-ansible.git
cd openshift-ansible/roles/openshift_examples/files/examples/latest/
for f in image-streams/image-streams-centos7.json; do cat $f | oc create -n openshift -f -; done
for f in db-templates/*.json; do cat $f | oc create -n openshift -f -; done
for f in quickstart-templates/*.json; do cat $f | oc create -n openshift -f -; done
```

# Add external nameserver
```
cat >> /etc/resolv.conf << '__EOF__'
nameserver 8.8.8.8
__EOF__
service docker restart
```

# Update Firewall to accept port 8443

```
firewall-cmd --permanent --zone=public --add-port=80/tcp
firewall-cmd --permanent --zone=public --add-port=443/tcp
firewall-cmd --permanent --zone=public --add-port=8443/tcp
firewall-cmd --reload
firewall-cmd --list-all

OR disable it

systemctl stop firewalld

AND

iptables -A INPUT -p tcp -m tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp -m tcp --dport 8443 -j ACCEPT
iptables-save | sudo tee /etc/sysconfig/iptables
service iptables restart

systemctl status iptables.service
chkconfig iptables off
```

# Temp

```
oc delete serviceaccount/registry
oc delete clusterrolebinding/registry-registry-role
oc delete dc/docker-registry
oc delete svc/docker-registry

oc delete serviceaccount/router
oc delete clusterrolebinding/router-router-role
oc delete dc/router
oc delete svc/router
```