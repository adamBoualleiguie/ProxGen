# ProxGen: IT utility to create proxmox VMs on demand

> As remediation and provide error prune solution linked to the task of vm creation.
> As solution, a terraform script that helps it bootstrap vms on demand by only setting list of specs and  vm temlate source
> In this Guideline, we present list of methods in order to setup a list of vms , the example will be taking the creation a pool of 7 VMs for a poc k8s cluster $
> 

# Key Benefits

When preparing for POC env or even a client (can occurs when client provide access to proxmox , low but possible), those tasks require so much time, especially when we talk about preparing guest VMs for a kubernetes cluster

as briefing:

- The concept of creating vms by downloading ISO is heavy and takes time installing the os on guest VM and configuring IT (Time Consuming)
- Error-prone process
- orphaned VMs

💡 This process will offer the following: 

- Using Terraform allows us to effectively track actions, especially by leveraging `terraform apply` and `terraform destroy` within GitLab CI.
- Cloud images, as opposed to ISO images, significantly speed up the process of setting up and configuring VMs (using cloud-init).
- Eliminates the need for manual edits to the netplan file for proper IP and gateway configuration.
- Facilitates the creation of VMs at scale with greater efficiency and consistency.

# About the Terraform script

This script uses Telmate/proxmox provider to communicate with the pve cluster api offering the flexibility to manage the creation of cloud-init disks and proxmox guest VMs

---

the vm created will be cloned from our os templates (in this case we will use centos9-Template)

---

for further details about the script , the [main.tf](http://main.tf) in commented for each block section 

# Using the script

## Requirements:

- installed Terraform on host machine (this is temporarry because the process will be just commiting in gitlab repo and pipeline will handle everything )

## Preparation

- As first measure, terraform need to pull the content of the provider and setup the tfstate etc  for that we need to init

`terraform init`

1. edit the terraform.tfvars: this file will contain an array of list of vms u want to create with it’s specs etc bellow u find an example 

⚠️ for some variables  u can not passing them , but some of them are mandatory (the [main.tf](http://main.tf) doc explains it )

```bash
# this is a show case explaining  how we are using the tf script to pass a number of vms to be created by terraform 
# this example is in reality a list of vms that will be useed by  kubespray ansible to bootstrap a cluster
vms = [
# Master nodes section######################
  {
    name        = "poc-tf-master1"
    target_node = "pve-node1"
    clone_template = "centos9-Template"
    cores       = 2
    memory      = 2048
    disk_size   = 10 
    ip_address  = "172.16.50.101/24"
    gateway     = "172.16.50.254"
    ciuser      = "master1"
    cipassword  = "erty"
  },
  {
    name        = "poc-tf-master2"
    target_node = "pve-node1"
    clone_template = "centos9-Template"
    cores       = 2
    memory      = 2048
    disk_size   = 10
    ip_address  = "172.16.50.102/24"
    gateway     = "172.16.50.254"
    ciuser      = "master2"
    cipassword  = "erty"
  }
]

```

1. for security measures, the pm creds for proxmox in the [main.tf](http://main.tf) are redacted,   for that exporting variables for proxmox creds is a solution 

```bash
export PM_USER="root@pam"
export PM_PASS="redacted"
```

### Provisioning vms

📓 This manner of work will be depricated since we will use the gitlab ci to record our vm creation events, this way all members will follow a good practice to create a vm and destroy it 

⚠️ When u  plan to boot a VM from a specific not IT member need to verify that the selected `clone_template` in the vars  is available on  the `target_node`

```bash
# plan to check the existing infra 
terraform plan 
# apply the change
# why -parallelism=1 ?  because some locking issues can occurs to proxmox server if many clone requests are done , the best choice is 2 to avoid issues 
terrafom apply -parallelism=2
```

### Destroying VMs

⚠️ Always make sure that u are on the correct workspace and state , since terraform remember the infra state using tfstate file, for that always   check with `terraform plan` 

```bash
# simple
terraform destroy -parallelism=2
```