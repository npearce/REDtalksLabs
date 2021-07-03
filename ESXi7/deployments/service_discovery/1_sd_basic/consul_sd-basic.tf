##############################################
#  ESXI Provider host/login details
##############################################
#
provider "esxi" {
  esxi_hostname = var.esxi_hostname
  esxi_hostport = var.esxi_hostport
  esxi_hostssl  = var.esxi_hostssl
  esxi_username = var.esxi_username
  esxi_password = var.esxi_password
}

##############################################
#  Required data for consul config files
##############################################
#
locals {
    servers_fqdn = "${join(", ", [ for k, v in data.dns_a_record_set.resolved: format("%q", v.id) ] )}"
    server_count = "${length(data.dns_a_record_set.resolved)}"
}

##############################################
#  Using DNS entries for Consul server addrs
##############################################
#
data "dns_a_record_set" "resolved" {
    for_each = var.server_settings
    host = "${each.value.name}.redtalks.lab"
}


##############################################
#  Create Consul Servers
##############################################
#
resource "esxi_guest" "ConsulServers" {
    for_each = var.server_settings

    guest_name = each.value.name
    disk_store = "ds1"
  
    boot_disk_type = "thin"
    boot_disk_size = "35"
  
    memsize            = "1024"
    numvcpus           = "1"
    resource_pool_name = "/"
    power              = "on"
  
#    clone_from_vm = "rtlabBaseImage"   # A VM runing on the ESXi server
#    ovf_source        = "../base_image/ESXi7/output-rtlabBaseVM/rtlabBaseVM.ova"
#    ovf_source        = "http://nas.redtalks.lab:8000/rtlabBaseVM.ova"
    ovf_source        = var.ova_url

    network_interfaces {
        virtual_network = "VM Network"
        mac_address     = each.value.mac_addr  # Mayeb we can auto-register DNS? https://github.com/gclayburg/synology-diskstation-scripts
        nic_type        = "vmxnet3"
    }

    guest_startup_timeout  = 45
    guest_shutdown_timeout = 30

    provisioner "file" {
        source      = "scripts/systemd-setup.sh"
        destination = "/tmp/systemd-setup.sh"
        connection {
            type     = "ssh"
            user     = var.vm_guest_username
            password = var.vm_guest_password
            host     = data.dns_a_record_set.resolved[each.key].addrs[0]
        }
    }

    provisioner "file" {
        content      = templatefile("${path.module}/config_templates/${each.value.product}_${each.value.mode}_${each.value.config}.hcl", { servers_fqdn = local.servers_fqdn, server_count = local.server_count })
        destination  = "/tmp/${each.value.product}_${each.value.mode}_${each.value.config}.hcl"
        connection {
            type     = "ssh"
            user     = var.vm_guest_username
            password = var.vm_guest_password
            host     = data.dns_a_record_set.resolved[each.key].addrs[0]
        }
    }

    provisioner "remote-exec" {
        inline = [
            "echo ${var.vm_guest_password} | sudo -S rm /etc/consul.d/*",
            "echo ${var.vm_guest_password} | sudo -S mv /tmp/${each.value.product}_${each.value.mode}_${each.value.config}.hcl /etc/consul.d/",
            "echo ${var.vm_guest_password} | sudo -S chown -R consul:consul /etc/consul.d",
            "echo ${var.vm_guest_password} | sudo -S chmod +x /tmp/systemd-setup.sh",
            "echo ${var.vm_guest_password} | sudo -S /tmp/systemd-setup.sh ${each.value.product} ${each.value.mode} ${each.value.config}",   # /setup-systemd.sh <subcommand> <option>
            "echo ${var.vm_guest_password} | sudo -S service consul restart",
        ]
        connection {
            type     = "ssh"
            user     = var.vm_guest_username
            password = var.vm_guest_password
            host     = data.dns_a_record_set.resolved[each.key].addrs[0]
        }
    }

}


##############################################
#  Create Consul Clients
##############################################
#
resource "esxi_guest" "ConsulClients" {
  for_each = var.client_settings

  guest_name = each.value.name
  disk_store = "ds1"
  
  boot_disk_type = "thin"
  boot_disk_size = "35"
  
  memsize            = "1024"
  numvcpus           = "1"
  resource_pool_name = "/"
  power              = "on"
  
#  clone_from_vm = "rtlabBaseImage"   # A VM runing on the ESXi server
#  ovf_source        = "../base_image/ESXi7/output-rtlabBaseVM/rtlabBaseVM.ova"
#  ovf_source        = "http://nas.redtalks.lab:8000/rtlabBaseVM.ova"
  ovf_source        = var.ova_url

  network_interfaces {
    virtual_network = "VM Network"
    nic_type        = "vmxnet3"
  }

  guest_startup_timeout  = 45
  guest_shutdown_timeout = 30

  provisioner "file" {
    source      = "scripts/systemd-setup.sh"
    destination = "/tmp/systemd-setup.sh"
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = self.ip_address
    }
  }

  provisioner "file" {
    content      = templatefile("${path.module}/config_templates/${each.value.product}_${each.value.mode}_${each.value.config}.hcl", { servers_fqdn = local.servers_fqdn, service_id = each.value.name, service_name = each.value.service })
    destination  = "/tmp/${each.value.product}_${each.value.mode}_${each.value.config}.hcl"
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = self.ip_address
    }
  }

  provisioner "remote-exec" {
    inline = [
      "echo ${var.vm_guest_password} | sudo -S rm /etc/consul.d/*",
      "echo ${var.vm_guest_password} | sudo -S hostnamectl set-hostname ${each.value.name}",
      "echo ${var.vm_guest_password} | sudo -S mv /tmp/${each.value.product}_${each.value.mode}_${each.value.config}.hcl /etc/consul.d/",
      "echo ${var.vm_guest_password} | sudo -S chown -R consul:consul /etc/consul.d",
      "echo ${var.vm_guest_password} | sudo -S chmod +x /tmp/systemd-setup.sh",
      "echo ${var.vm_guest_password} | sudo -S /tmp/systemd-setup.sh ${each.value.product} ${each.value.mode} ${each.value.config}",   # /setup-systemd.sh <subcommand> <option>
      "echo ${var.vm_guest_password} | sudo -S service consul restart",
    ]
    connection {
      type     = "ssh"
      user     = var.vm_guest_username
      password = var.vm_guest_password
      host     = self.ip_address
    }
  }

}