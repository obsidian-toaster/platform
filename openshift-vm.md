# Install Openshift oc client
```
curl -OL https://github.com/openshift/origin/releases/download/v1.3.2/openshift-origin-client-tools-v1.3.2-ac1d579-linux-64bit.tar.gz
tar -vxf openshift-origin-client-tools-v1.3.2-ac1d579-linux-64bit.tar.gz
cd openshift-origin-client-tools-v1.3.2-ac1d579-linux-64bit
cp oc /usr/local/bin
```

# Install Yum packages
```
yum install wget git net-tools bind-utils iptables-services bridge-utils bash-completion
yum update
yum install docker
```

# Change Security level for Docker

```
vi /etc/sysconfig/docker

# INSECURE_REGISTRY='--insecure-registry'
INSECURE_REGISTRY='--insecure-registry 172.30.0.0/16'

sudo systemctl restart docker
```

# Change Dnsmasq port
```
vi /etc/dnsmasq.conf
#port=53
port=5353
```
# Restart the machine 

reboot

# Start Openshift

```
oc cluster up --public-hostname=172.16.50.40
oc login -u system:admin
```
# Enable docker Service

```
sudo systemctl enable docker
```

# Update Firewall

```
sudo firewall-cmd --zone=public --add-port=8443/tcp --permanent
sudo firewall-cmd --reload
firewall-cmd --list-all
```
