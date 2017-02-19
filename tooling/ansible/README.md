# Instructions

## Create a Centos VM

- Open a terminal on your laptop (MacBook Pro, ...) 
- Execute these lines to setup a Centos VM machine accessible at this IP Address `172.28.128.4`

```
mkdir -p ~/Temp/_rhel7
cd ~/Temp/_rhel7

cat << 'EOF' > Vagrantfile 
# for running the CD Pipeline we recommend at least 400 for memory!
$vmMemory = Integer(ENV['VM_MEMORY'] || 4000)

# Override the default VM name appearing within VirtualBox
$vmName = ENV['VM_NAME'] || "rhel7-openshift"

$script = <<SCRIPT
yum -y install net-tools subscription-manager 

# Register user and add the required repos
subscription-manager register --username=qa@redhat.com --password=EC3YWpKxSe524GCK --force
subscription-manager subscribe --pool=8a85f9823e3d5e43013e3ddd4e2a0977
subscription-manager repos --enable rhel-7-server-extras-rpms 
subscription-manager repos --enable rhel-7-server-optional-rpms   
subscription-manager repos --enable rhel-7-server-ose-3.4-rpms

# Add user_key to authorized key file to allow to ssh using root 
mkdir -p /root/.ssh
cat /home/vagrant/user_key.pub > /root/.ssh/authorized_keys

# Authorize root access without password
cat << 'EOF' >> /etc/ssh/sshd_config
PermitRootLogin without-password  
RSAAuthentication yes
PubkeyAuthentication yes
EOF

chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

service sshd restart

SCRIPT

Vagrant.configure("2") do |config|

  config.vm.box = "samdoran/rhel7"

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

  config.vm.provision "file", source: "~/.ssh/id_rsa.pub", destination: "/home/vagrant/user_key.pub"
  config.vm.provision "shell", inline: $script, keep_color: true

end
EOF

vagrant up
```

## Chang the ~/.ssh/config file

- Add the host entry of the VM within the ` ~/.ssh/config` file

```
Host 172.28.128.4
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
    IdentitiesOnly yes
    User root
    IdentityFile ~/.ssh/id_rsa.pub
    PasswordAuthentication no
```

## Imported public_key to authorized

- Log to VM 
```
vagrant ssh
sudo su -
```

- Add the public key of the user machine that you will use to access the VM and copy it within the `/root/.ssh/authorized_keys` of the VM
```
mkdir /root/.ssh/
touch /root/.ssh/authorized_keys
```

- Update the /etc/ssh/sshd_config file of the VM.
```
PermitRootLogin without-password  
RSAAuthentication yes
PubkeyAuthentication yes
```

## DNS & Hostname

https://developers.redhat.com/blog/2016/05/27/use-vagrant-landrush-to-add-dns-features-to-your-openshift-cdk-machine/

## Install Ansible 2.2.0

- Use `pip` to install ansible on your machine & these libs

```
pip install ansible==2.2.0
pip install urlparse2
pip install pyopenssl
```

## Clone OpenShift Ansible's Sally repo

```
git clone  git@github.com:sallyom/online.git
mv online/ sally-online
cd sally-online
git checkout remotes/origin/no_aws
cd ansible; git submodule init; git submodule update;
```

# Curl the rpm files
```
#curl -OL http://download.eng.bos.redhat.com/brewroot/packages/openshift-scripts/3.4.1.8/1.el7/x86_64/openshift-scripts-dedicated-3.4.1.8-1.el7.x86_64.rpm
#curl -OL http://download.eng.bos.redhat.com/brewroot/packages/openshift-scripts/3.4.1.8/1.el7/x86_64/openshift-scripts-devpreview-3.4.1.8-1.el7.x86_64.rpm
curl -OL http://download.eng.bos.redhat.com/brewroot/packages/openshift-scripts/3.4.1.8/1.el7/x86_64/openshift-scripts-paid-3.4.1.8-1.el7.x86_64.rpm
```
# Change IP address

- Edit `inventory/noaws/static_inv` and change `ip_address` to use the private IP address `172.28.128.4`
- Edit `vars/deploy_vars.yml` and change `vm_ip` to use the private IP address `172.28.128.4`
- Edit `vars/deploy_vars.yml` and change `your_local_name_setup` to use `vagrant.ocp`


# Run script
```
ansible-playbook devenv-launch.yml -i inventory/noaws/static-inv        
```

The message is still there during installation process "The hostname "vagrant.ocp" for "vagrant.ocp" doesn't resolve to an ip address owned by this host. Please set openshift_hostname variable to a hostname that when resolved on the host in question resolves to an IP address matching an interface on this host"

- As the error reported within the log of openshift was due to an issue to access the etcd daemon, I changed the IP address within the config file "/etc/origin/master/master-config.yaml" and restarted openshift "service atomic-openshift-master restart"

https://gist.github.com/cmoulliard/fe6a9e90b1618a67f23075a10d94c51c#file-gistfile1-txt-L53

sed -i "s/router.default.svc.cluster.local/$HOST_IP.xip.io/" $OPENSHIFT/openshift.local.config/master/master-config.yaml

```
admissionConfig:
apiLevels:
- v1
apiVersion: v1
assetConfig:
  logoutURL: ""
  masterPublicURL: https://vagrant.ocp:8443
  publicURL: https://vagrant.ocp:8443/console/
  extensionScripts:
  - /etc/openshift-online/ui-extensions/assets/extensions/online-extensions.js
  - /etc/openshift-online/ui-extensions/assets/extensions/online-notifications.js
  extensionStylesheets:
  - /etc/openshift-online/ui-extensions/assets/extensions/online-extensions.css
  extensions:
  - name: notifications
    sourceDirectory: /etc/openshift-online/ui-extensions/assets/extensions/
  servingInfo:
    bindAddress: 0.0.0.0:8443
    bindNetwork: tcp4
    certFile: master.server.crt
    clientCA: ""
    keyFile: master.server.key
    maxRequestsInFlight: 0
    requestTimeoutSeconds: 0
controllerConfig:
  serviceServingCert:
    signer:
      certFile: service-signer.crt
      keyFile: service-signer.key
controllers: '*'
corsAllowedOrigins:
  - 127.0.0.1
  - localhost
  - 10.0.2.15
  - kubernetes.default
  - kubernetes.default.svc.cluster.local
  - kubernetes
  - openshift.default
  - openshift.default.svc
  - 172.30.0.1
  - vagrant.ocp
  - openshift.default.svc.cluster.local
  - kubernetes.default.svc
  - openshift
dnsConfig:
  bindAddress: 0.0.0.0:8053
  bindNetwork: tcp4
etcdClientInfo:
  ca: master.etcd-ca.crt
  certFile: master.etcd-client.crt
  keyFile: master.etcd-client.key
  urls:
    - https://10.0.2.15:2379
etcdStorageConfig:
  kubernetesStoragePrefix: kubernetes.io
  kubernetesStorageVersion: v1
  openShiftStoragePrefix: openshift.io
  openShiftStorageVersion: v1
imageConfig:
  format: registry.ops.openshift.com/openshift3/ose-${component}:v3.4.1.5
  latest: false
imagePolicyConfig:
  disableScheduledImport: true
  maxImagesBulkImportedPerRepository: 3
kind: MasterConfig
kubeletClientInfo:
  ca: ca.crt
  certFile: master.kubelet-client.crt
  keyFile: master.kubelet-client.key
  port: 10250
kubernetesMasterConfig:
  admissionConfig:
    pluginConfig:
      {}
  apiServerArguments:
  controllerArguments:
    enable-hostpath-provisioner:
    - 'true'
    pvclaimbinder-sync-period:
    - 30s
  masterCount: 1
  masterIP: 10.0.2.15
  podEvictionTimeout:
  proxyClientInfo:
    certFile: master.proxy-client.crt
    keyFile: master.proxy-client.key
  schedulerArguments:
  schedulerConfigFile: /etc/origin/master/scheduler.json
  servicesNodePortRange: ""
  servicesSubnet: 172.30.0.0/16
  staticNodeNames: []
masterClients:
  externalKubernetesClientConnectionOverrides:
    acceptContentTypes: application/vnd.kubernetes.protobuf,application/json
    contentType: application/vnd.kubernetes.protobuf
    burst: 400
    qps: 200
  externalKubernetesKubeConfig: ""
  openshiftLoopbackClientConnectionOverrides:
    acceptContentTypes: application/vnd.kubernetes.protobuf,application/json
    contentType: application/vnd.kubernetes.protobuf
    burst: 600
    qps: 300
  openshiftLoopbackKubeConfig: openshift-master.kubeconfig
masterPublicURL: https://vagrant.ocp:8443
networkConfig:
  clusterNetworkCIDR: 10.128.0.0/14
  hostSubnetLength: 9
  networkPluginName: redhat/openshift-ovs-subnet
# serviceNetworkCIDR must match kubernetesMasterConfig.servicesSubnet
  serviceNetworkCIDR: 172.30.0.0/16
  externalIPNetworkCIDRs:
  - 0.0.0.0/0
oauthConfig:
  assetPublicURL: https://vagrant.ocp:8443/console/
  grantConfig:
    method: auto
  identityProviders:
  - challenge: true
    login: true
    mappingMethod: add
    name: allow_all
    provider:
      apiVersion: v1
      kind: AllowAllPasswordIdentityProvider
  masterCA: ca-bundle.crt
  masterPublicURL: https://vagrant.ocp:8443
  masterURL: https://vagrant.ocp:8443
  sessionConfig:
    sessionMaxAgeSeconds: 3600
    sessionName: ssn
    sessionSecretsFile: /etc/origin/master/session-secrets.yaml
  tokenConfig:
    accessTokenMaxAgeSeconds: 86400
    authorizeTokenMaxAgeSeconds: 500
pauseControllers: false
policyConfig:
  bootstrapPolicyFile: /etc/origin/master/policy.json
  openshiftInfrastructureNamespace: openshift-infra
  openshiftSharedResourcesNamespace: openshift
projectConfig:
  defaultNodeSelector: ""
  projectRequestMessage: ""
  projectRequestTemplate: "default/project-request"
  securityAllocator:
    mcsAllocatorRange: "s0:/2"
    mcsLabelsPerProject: 5
    uidAllocatorRange: "1000000000-1999999999/10000"
routingConfig:
  subdomain:  "172.28.128.4.vagrant.ocp"
serviceAccountConfig:
  limitSecretReferences: false
  managedNames:
  - default
  - builder
  - deployer
  masterCA: ca-bundle.crt
  privateKeyFile: serviceaccounts.private.key
  publicKeyFiles:
  - serviceaccounts.public.key
servingInfo:
  bindAddress: 0.0.0.0:8443
  bindNetwork: tcp4
  certFile: master.server.crt
  clientCA: ca.crt
  keyFile: master.server.key
  maxRequestsInFlight: 500
  requestTimeoutSeconds: 3600
volumeConfig:
  dynamicProvisioningEnabled: True
```

- After the installation, I added the cluster-role-to-user to my admin user
```
oc login -u system:admin
oc adm policy add-cluster-role-to-user cluster-admin admin
oc login -u admin -p admin
```

- Added also the missing templates

```
cd $TEMP_DIR
git clone https://github.com/openshift/openshift-ansible.git
cd openshift-ansible/roles/openshift_examples/files/examples/latest/
for f in image-streams/image-streams-centos7.json; do cat $f | oc create -n openshift -f -; done
for f in db-templates/*.json; do cat $f | oc create -n openshift -f -; done
for f in quickstart-templates/*.json; do cat $f | oc create -n openshift -f -; done
```