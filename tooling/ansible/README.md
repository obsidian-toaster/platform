# Instructions

## Create a RHEL7 VM

- Open a terminal on your laptop (MacBook Pro, ...) 
- Execute these lines to setup a RHEL 7 VM machine accessible at this private IP Address `172.28.128.4`

Remarks:
- Change the username/password a poolid according to your account.

```
mkdir -p ~/Temp/_rhel7
cd ~/Temp/_rhel7

cat << 'EOF' > Vagrantfile 
# for running the CD Pipeline we recommend at least 400 for memory!
$vmMemory = Integer(ENV['VM_MEMORY'] || 4000)

# Override the default VM name appearing within VirtualBox
$vmName = ENV['VM_NAME'] || "rhel7-oll-penshift"

$script = <<SCRIPT
yum -y install net-tools subscription-manager 

# Register user and add the required repos
subscription-manager register --username=USERNAME --password=PASSWORD --force
subscription-manager subscribe --pool=POOLID
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
  config.vm.hostname = "my." + $tld

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

## Change locally your ~/.ssh/config file

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

## Install Ansible 2.2.0 on your local machine

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
# Change some vars
 
- Edit the file `vars/deploy_vars.yml` and change `vm_ip` to use the private IP address `172.28.128.4`
- Edit the file `vars/deploy_vars.yml` and change `your_local_name_setup` to use `vagrant.ocp`

# Modify some files

- Add these lines at line 145 within the file `ansible/openshift-ansible/roles/etcd_server_certificates/tasks/main.yml` till Sally's project is updated

```
- name: Create a tarball of the etcd ca certs
  command: >
    tar -czvf {{ etcd_generated_certs_dir }}/{{ etcd_ca_name }}.tgz
      -C {{ etcd_ca_dir }} .
  args:
    creates: "{{ etcd_generated_certs_dir }}/{{ etcd_ca_name }}.tgz"
    warn: no
  when: etcd_server_certs_missing | bool
  delegate_to: "{{ etcd_ca_host }}"

- name: Retrieve etcd ca cert tarball
  fetch:
    src: "{{ etcd_generated_certs_dir }}/{{ etcd_ca_name }}.tgz"
    dest: "{{ g_etcd_server_mktemp.stdout }}/"
    flat: yes
    fail_on_missing: yes
    validate_checksum: yes
  when: etcd_server_certs_missing | bool
  delegate_to: "{{ etcd_ca_host }}"

- name: Ensure ca directory exists
  file:
    path: "{{ etcd_ca_dir }}"
    state: directory
  when: etcd_server_certs_missing | bool

- name: Unarchive etcd ca cert tarballs
  unarchive:
    src: "{{ g_etcd_server_mktemp.stdout }}/{{ etcd_ca_name }}.tgz"
    dest: "{{ etcd_ca_dir }}"
  when: etcd_server_certs_missing | bool

```

# Change RPM name 

Edit the file `ansible/roles/install_online_scripts_rpm/tasks/main.yml` and change the name of file accordign to the RPM downloaded

```
 - name: sync local rpm over
   synchronize:
     # src: "{{ hostvars.localhost.local_online_path }}/ansible/openshift-scripts-paid-3.4.1.8-1.git.5.59a9c2b.fc25.x86_64.rpm"
     src: "{{ hostvars.localhost.local_online_path }}/ansible/openshift-scripts-paid-3.4.1.8-1.el7.x86_64.rpm"
     # dest: /opt/openshift-scripts-paid-3.4.1.8-1.git.5.59a9c2b.fc25.x86_64.rpm
     dest: /opt/openshift-scripts-paid-3.4.1.8-1.el7.x86_64.rpm
```

# Setup a all-in-one inventory file

Don't add under the `[OSEv3:children]` a `lb` block or `etcd.` 
As `lb` will install an external load balancer which is not the HA Proxy and not required, we can remove it. Moreover it will conflict with
OpenShift HTTP Server as they both use the same port number `8443`. 
If you add `etcd`, then the ansible script will add within the config file of the etcd daemon a cluster section which is nto well configured 
and responsible to crash the OpenShift Server.

```
[OSEv3:children]
masters
nodes

[OSEv3:vars]
ansible_ssh_user=root
ansible_become=no
debug_level=2
deployment_type=openshift-enterprise
# TODO - Check with ansible guys if we can't avoid to hard code the url
openshift_master_etcd_urls=['https://10.0.2.15:2379']
openshift_hostname=my.vagrant.ocp
openshift_master_master_count=1
#openshift_master_identity_providers=[{'name': 'htpasswd_auth', 'login': 'true', 'challenge': 'true', 'kind': 'HTPasswdPasswordIdentityProvider', 'filename': '/etc/origin/master/htpasswd'}]

[masters]
my.vagrant.ocp

#
# This is an external loadbalancer which is not required here
#[lb]
#my.vagrant.ocp

[nodes]
my.vagrant.ocp openshift_schedulable=true openshift_node_labels="{'region': 'infra'}"
```

# Run script

```
ansible-playbook devenv-launch.yml -i inventory/all/static      
```

Remarks:

- During the execution of the script, this message will appear but you can ignore it
```
The hostname "vagrant.ocp" for "vagrant.ocp" doesn't resolve to an ip address owned by this host. Please set openshift_hostname variable to a hostname that when resolved on the host in question resolves to an IP address matching an interface on this host
```

- This problem occurs [randomly](https://github.com/openshift/openshift-ansible/issues/3433) and the workaround is to relaunch the ansible script

# To remove

```
ansible-playbook openshift-ansible/playbooks/adhoc/uninstall.yml -i inventory/all/static
```