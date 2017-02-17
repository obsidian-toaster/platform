# Instructions

## Create a Centos VM

- Open a terminal on your laptop (MacBook Pro, ...) 
- Execute these lines to setup a Centos VM machine accessible at this IP Address `172.28.128.4`

```
mkdir -p ~/Temp/_centos7/vagrant-openshift
cd ~/Temp/_centos7/vagrant-openshift

cat << 'EOF' > Vagrantfile 

# -*- mode: ruby -*-
# vi: set ft=ruby :

# for running the CD Pipeline we recommend at least 400 for memory!
$vmMemory = Integer(ENV['VM_MEMORY'] || 4000)

# Override the default VM name appearing within VirtualBox
$vmName = ENV['VM_NAME'] || "centos7-openshift"

$script = <<SCRIPT
yum -y install net-tools
SCRIPT

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

  config.vm.provision "shell", inline: $script, keep_color: true

end
EOF

vagrant up --provider virtualbox
```

## Install Ansible 2.2.0
```
pip install ansible==2.2.0
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
curl -OL http://download.eng.bos.redhat.com/brewroot/packages/openshift-scripts/3.4.1.8/1.el7/x86_64/openshift-scripts-dedicated-3.4.1.8-1.el7.x86_64.rpm
curl -OL http://download.eng.bos.redhat.com/brewroot/packages/openshift-scripts/3.4.1.8/1.el7/x86_64/openshift-scripts-devpreview-3.4.1.8-1.el7.x86_64.rpm
curl -OL http://download.eng.bos.redhat.com/brewroot/packages/openshift-scripts/3.4.1.8/1.el7/x86_64/openshift-scripts-paid-3.4.1.8-1.el7.x86_64.rpm
```
# Change IP address

- Edit `inventory/noaws/static_inv` and change `ip_address`
- Edit `vars/deploy_vars.yml` and change `vm_ip`
- Edit `vars/deploy_vars.yml` and change `your_local_name_setup` to use `xip.io`

# Run script
```
ansible-playbook devenv-launch.yml -i inventory/noaws/static-inv        
```