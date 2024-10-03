# Belongs to IT team
# this tf will help IT team bootstrap Vms  much more faster with specific configs using cloud-init 
# this will help team avoid the use of heavy ISO images to launch VM ,also the long time configuring VMS 
# TBD: The documentation is available on Notion , and will be shared in this repo 

terraform {
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.1-rc4"
    }
  }
}

provider "proxmox" {
  pm_tls_insecure = true
  pm_api_url      = "https://<proxmox-IP>:8006/api2/json"
  # in notion doc u find how to create a specific user, and the needed role to be used so this tf bootstrap vms 
  # and regarding the bootstrap of VMs from the gitlab ci  those creds will be passed as secrect CICD variables 
  # export PM_USER="terraform-prov@pve"
  # export PM_PASS="password"
  pm_debug = true
}

# Define variables for VM settings with default values
variable "vms" {
  type = list(object({
    # this is the name of the vm u want to bootstrap
    name = string
    # on what pve node u want to launch it 
    target_node = string
    # what cloud-init ready  template vm u want to bootrap from #TBD share the link to notion doc explaining how we create the vm templates that supports cloud init 
    clone_template = string
    # as name says the number of cores 
    cores = number
    # ram 
    memory = number
    # disk size for the os
    disk_size = number
    # set the network tag for the vm since  all pve nodes are vlan aware
    network_tag = number
    # the ip  but with cidr  check default  example  u pass this : 172.16.1.13/24
    ip_address = string
    # the gateway ip example u pass this: 172.16.1.254
    gateway = string
    # this is the default user u want to bootstrap from   and this is required 
    ciuser = string
    # what password u want for this VM 
    cipassword = string
  }))
  # If you don't pass a specific variable in the tfvars,  those are the defaults
  # some of the varaibles will be disabled from default to avoid conflicts and vms deletions 
  # herre is the list: name,target-node,ip and gateway address, 
  default = [
    {
      name           = "vm-default-1"
      target_node    = "pve-node1"
      clone_template = "centos9-Template"
      cores          = 2
      memory         = 3000
      disk_size      = 32
      network_tag    = 50
      ip_address     = "172.16.1.13/24"
      gateway        = "172.16.1.254"
      ciuser         = "default_user"
      cipassword     = "default_password"
    }
  ]
}

# Create multiple VMs based on the variable list
resource "proxmox_vm_qemu" "cloudinit_vms" {
  count = length(var.vms)

  name        = var.vms[count.index].name
  target_node = var.vms[count.index].target_node
  clone       = var.vms[count.index].clone_template
  agent       = 1
  os_type     = "cloud-init"
  cores       = var.vms[count.index].cores
  memory      = var.vms[count.index].memory
  scsihw      = "virtio-scsi-single"

  disks {
    scsi {
      scsi2 {
        cloudinit {
          storage = "local-lvm"
        }
      }
      scsi0 {
        disk {
          size     = var.vms[count.index].disk_size
          cache    = "writeback"
          storage  = "local-lvm"
          iothread = false
          discard  = true
        }
      }
    }
  }

  network {
    model  = "virtio"
    bridge = "vmbr0"
    tag    = var.vms[count.index].network_tag
  }

  boot       = "order=scsi0"
  ipconfig0  = "ip=${var.vms[count.index].ip_address},gw=${var.vms[count.index].gateway}"
  ciuser     = var.vms[count.index].ciuser
  cipassword = var.vms[count.index].cipassword
  # this ssh key will be shared in secure ways, such key will be able to log in any created VM by this  tf script
  sshkeys = <<EOF
    # pass   public key here so when vm created will accepts SSH with it s private key directly 
    EOF
}
