# GCE

## Instructions

https://github.com/openshift/openshift-ansible/blob/master/README_GCE.md

## Install Ansible 2.2.0

- Use `pip` to install ansible on your machine & these libs

```
pip install ansible==2.2.0
pip install pycrypto
```

## To get the Project ID

- open this link in your browser "https://console.cloud.google.com/iam-admin/settings/project"
- Copy/paste the value defined under `Project ID`

## To get the key

- Select within the dashboard the `Api Manager`. Next click on credentials
- Click on "Manage Service Accounts" - https://console.cloud.google.com/iam-admin/serviceaccounts/project?project=luminous-empire-149609
- At the line of `Compute Engine default service account`, click on the button to generate a p12 key and save it
- Convert the p12 file into & pem as required by ansible

```
cp ~/Downloads/My\ Project-2b28608e893e.p12 project-2b28608e893e.p12
export GCE_KEY_HASH=2b28608e893e
export PROJECT_ID=luminous-empire-149609
export PROJECT_NAME=project
openssl pkcs12 -in "${PROJECT_NAME}-${GCE_KEY_HASH}.p12" -passin pass:notasecret -nodes -nocerts | openssl rsa -out ${PROJECT_ID}-${GCE_KEY_HASH}.pem
```
## Create a gce.ini file for GCE

* gce_service_account_email_address - Found in "APIs & auth" -> Credentials -> "Service Account" -> "Email Address"
* gce_service_account_pem_file_path - Full path from previous steps
* gce_project_id - Found in "Projects", it list all the gce projects you are associated with.  The page lists their "Project Name" and "Project ID".  You want the "Project ID"

Mandatory customization variables (check the values according to your tenant):
* zone = europe-west1-d
* network = default

Optional Variable Overrides:
* gce_ssh_user - ssh user, defaults to the current logged in user
* gce_machine_type = n1-standard-1 - default machine type
* gce_machine_etcd_type = n1-standard-1 - machine type for etcd hosts
* gce_machine_master_type = n1-standard-1 - machine type for master hosts
* gce_machine_node_type = n1-standard-1 - machine type for node hosts
* gce_machine_image = centos-7 - default image
* gce_machine_etcd_image = centos-7 - image for etcd hosts
* gce_machine_master_image = centos-7 - image for master hosts
* gce_machine_node_image = centos-7 - image for node hosts


1. vi ~/Temp/_gce/gce.ini
1. make the contents look like this:
```
[gce]
gce_service_account_email_address = long...@developer.gserviceaccount.com
gce_service_account_pem_file_path = /full/path/to/project_id-gce_key_hash.pem
gce_project_id = project_id
zone = europe-west1-d
network = default
gce_machine_type = n1-standard-2
gce_machine_master_type = n1-standard-1
gce_machine_node_type = n1-standard-2
gce_machine_image = centos-7
gce_machine_master_image = centos-7
gce_machine_node_image = centos-7

```
1. Define the environment variable GCE_INI_PATH so gce.py can pick it up and bin/cluster can also read it
```
export GCE_INI_PATH=~/Temp/_gce/gce.ini
```

Test The Setup
--------------
1. cd openshift-ansible/
1. Try to list all instances (Passing an empty string as the cluster_id
argument will result in all gce instances being listed)
```
  bin/cluster list gce ''
```

Creating a cluster
------------------
1. To create a cluster with one master, one infra node, and two compute nodes
```
  bin/cluster create gce <cluster-id>
```
1. To create a cluster with 3 masters, 3 etcd hosts, 2 infra nodes and 10
compute nodes
```
  bin/cluster create gce -m 3 -e 3 -i 2 -n 10 <cluster-id>
```


