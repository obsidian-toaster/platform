# Instructions

## Create a RHEL7 VM

- Open a terminal on your laptop (MacBook Pro, ...) 
- Execute these lines to setup a RHEL 7 VM machine accessible at this private IP Address `172.28.128.4` with Vagrant (version used : 1.8.7)

Remark:
- Change the `username/password` an `poolid` according to your account within the `Vagrantfile`

```
mkdir -p ~/Temp/_rhel7
cd ~/Temp/_rhel7

cat << 'EOF' > Vagrantfile 
# for running the CD Pipeline we recommend at least 3000 for memory!
$vmMemory = Integer(ENV['VM_MEMORY'] || 3000)

# Override the default VM name appearing within VirtualBox
$vmName = ENV['VM_NAME'] || "rhel7-oll-penshift"

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

# Clone OpenShift Ansible's Sally repo

```
git clone git@github.com:sallyom/online.git
mv online/ sally-online
cd sally-online
git checkout remotes/origin/no_aws
cd ansible; git submodule init; git submodule update;
```

## Curl the rpm files
```
#curl -OL http://download.eng.bos.redhat.com/brewroot/packages/openshift-scripts/3.4.1.8/1.el7/x86_64/openshift-scripts-dedicated-3.4.1.8-1.el7.x86_64.rpm
#curl -OL http://download.eng.bos.redhat.com/brewroot/packages/openshift-scripts/3.4.1.8/1.el7/x86_64/openshift-scripts-devpreview-3.4.1.8-1.el7.x86_64.rpm
curl -OL http://download.eng.bos.redhat.com/brewroot/packages/openshift-scripts/3.4.1.8/1.el7/x86_64/openshift-scripts-paid-3.4.1.8-1.el7.x86_64.rpm
```

## Change some vars
 
- Edit the file `vars/deploy_vars.yml` and change `vm_ip` to use the private IP address `172.28.128.4`
- Edit the file `vars/deploy_vars.yml` and change `your_local_name_setup` to use `xip.io`

## Modify some files

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


- Add these lines within this file `ansible/openshift-ansible/roles/os_firewall/library/os_firewall_manage_iptables.py` in order to avoid the [issue](https://github.com/openshift/openshift-ansible/issues/3433) 

```
    def gen_cmd(self):
        cmd = 'iptables' if self.ip_version == 'ipv4' else 'ip6tables'
        # Include -w (wait for xtables lock) in default arguments.
        default_args = ['-w']
        return ["/usr/sbin/%s" % cmd] + default_args
```

## Change RPM name 

Edit the file `ansible/roles/install_online_scripts_rpm/tasks/main.yml` and change the name of file accordign to the RPM downloaded

```
 - name: sync local rpm over
   synchronize:
     # src: "{{ hostvars.localhost.local_online_path }}/ansible/openshift-scripts-paid-3.4.1.8-1.git.5.59a9c2b.fc25.x86_64.rpm"
     src: "{{ hostvars.localhost.local_online_path }}/ansible/openshift-scripts-paid-3.4.1.8-1.el7.x86_64.rpm"
     # dest: /opt/openshift-scripts-paid-3.4.1.8-1.git.5.59a9c2b.fc25.x86_64.rpm
     dest: /opt/openshift-scripts-paid-3.4.1.8-1.el7.x86_64.rpm
```

## Edit hostname on the VM

- Edit the `/etc/hosts` file of the VM in order to add the IP Address and to comment the line containing the ipv6 entries

```
172.28.128.4	my.vagrant.ocp	my
127.0.0.1	my.vagrant.ocp	my
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
```

# Setup a all-in-one inventory file

Don't add under the `[OSEv3:children]` a `lb` block or `etcd.` 

As `lb` will install an external load balancer which is not the HA Proxy and not required, we can remove it. Moreover it will conflict with
OpenShift HTTP Server as they both use the same port number `8443`. 

If you add `etcd`, then the ansible script will add within the config file of the etcd daemon a cluster section which is not well configured 
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

# TODO : Should not be hard coded
openshift_master_etcd_urls=['https://10.0.2.15:2379']

openshift_common_hostname=my.vagrant.ocp
openshift_hostname=my.vagrant.ocp

# TODO : Maybe a workaround to avoid the hostname error
# Line "172.28.128.4    my.vagrant.ocp" has been added to the /etc/hosts file of the VM
# and lines starting with ::1 removed as they correspond to ipv6 entries
openshift_set_hostname=True

openshift_master_master_count=1

# Enable to avoid ca cart copy issue
openshift_use_flannel=false

# TODO : Error reported - https://github.com/openshift/openshift-ansible/issues/3450
# openshift_hosted_metrics_deploy=true

[masters]
my.vagrant.ocp

#
# This is an external loadbalancer which is not required here
#[lb]
#my.vagrant.ocp

[nodes]
my.vagrant.ocp openshift_schedulable=true openshift_node_labels="{'region': 'infra'}"
```

## Run script

```
ansible-playbook devenv-launch.yml -i inventory/all/static      
```

Remarks:

- During the execution of the script, this message will appear but you can ignore it
```
The hostname "vagrant.ocp" for "vagrant.ocp" doesn't resolve to an ip address owned by this host. Please set openshift_hostname variable to a hostname that when resolved on the host in question resolves to an IP address matching an interface on this host
```

- This problem occurs [randomly](https://github.com/openshift/openshift-ansible/issues/3433).
  The workaround (till the project is rebased) is to apply this [change](ttps://github.com/openshift/openshift-ansible/pull/3152/commits/86d10d306967922be894ddd19fcf49382a522b75)

- Ansible will also complain that a project template has already been installed
```
TASK [online_project_request : create Online default/project-request] **********
Tuesday 21 February 2017  14:18:44 +0100 (0:00:00.516)       0:11:07.960 ******
changed: [my.vagrant.ocp]
fatal: [172.28.128.4]: FAILED! => {"changed": true, "cmd": "oc create -f project-request.json -n default", "delta": "0:00:00.265071", "end": "2017-02-21 13:18:45.305071", "failed": true, "rc": 1, "start": "2017-02-21 13:18:45.040000", "stderr": "Error from server: error when creating \"project-request.json\": templates \"project-request\" already exists", "stdout": "", "stdout_lines": [], "warnings": []}
```

## To uninstall

```
ansible-playbook openshift-ansible/playbooks/adhoc/uninstall.yml -i inventory/all/static
```