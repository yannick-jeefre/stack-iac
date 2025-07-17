terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~> 0.66"
    }
  }
}

provider "proxmox" {
  endpoint = var.proxmox_api_url
  username = var.proxmox_user
  password = var.proxmox_password
  insecure = true
}

resource "proxmox_virtual_environment_vm" "vm" {
  count     = 2
  name      = "vm-${count.index}"
  node_name = var.node_name
  
  clone {
    vm_id = 100
  }
  
  cpu {
    cores = 2
  }
  
  memory {
    dedicated = 2048
  }
  
  network_device {
    bridge = "vmbr0"
    model  = "virtio"
  }
  
  agent {
    enabled = true
  }
  
  startup {
    order      = 1
    up_delay   = 30
  }
  
  # Provisioner simple sans sudo
  provisioner "remote-exec" {
    inline = [
      "echo 'Connexion SSH établie'",
      "mkdir -p ~/.ssh",
      "chmod 700 ~/.ssh",
      "echo '${file(pathexpand("~/.ssh/id_rsa.pub"))}' >> ~/.ssh/authorized_keys",
      "chmod 600 ~/.ssh/authorized_keys",
      "echo 'Configuration SSH terminée avec succès'"
    ]
    
    connection {
      type     = "ssh"
      user     = var.template_username
      password = var.template_password
      host     = self.ipv4_addresses[1][0]
      timeout  = "5m"
    }
  }
}

# Outputs
output "vm_ips" {
  description = "IP addresses of created VMs"
  value = {
    for i, vm in proxmox_virtual_environment_vm.vm : 
    vm.name => vm.ipv4_addresses[1][0]
  }
}

output "vm_ips_list" {
  description = "List of IP addresses for Ansible inventory"
  value = [
    for vm in proxmox_virtual_environment_vm.vm : 
    vm.ipv4_addresses[1][0]
  ]
}

# Générer l'inventaire Ansible
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/inventory.tpl", {
    vms = proxmox_virtual_environment_vm.vm
  })
  filename = "${path.module}/ansible_inventory.yml"
}

