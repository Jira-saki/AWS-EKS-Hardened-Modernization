terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.7.6"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

# 1. Storage Pool
resource "libvirt_pool" "ep2_pool" {
  name = "ep2_pool"
  type = "dir"
  path = "/var/lib/libvirt/images/ep2-pool"
}

# 2. Base Image Volume
resource "libvirt_volume" "ubuntu_base" {
  name   = "ubuntu-jammy-base.qcow2"
  pool   = libvirt_pool.ep2_pool.name
  source = "/var/lib/libvirt/images/iso/jammy-server-cloudimg-amd64.img"
  format = "qcow2"
}

# 3. Isolated Network Subnet (192.168.150.0/24)
resource "libvirt_network" "k8s_net" {
  name      = "ep2-k8s-net"
  mode      = "nat"
  domain    = "k8s.local"
  addresses = ["192.168.150.0/24"]

  dhcp {
    enabled = true
  }

  dns {
    enabled = true
    hosts {
      hostname = "controlplane"
      ip       = "192.168.150.10"
    }
    hosts {
      hostname = "worker-node01"
      ip       = "192.168.150.11"
    }
    hosts {
      hostname = "worker-node02"
      ip       = "192.168.150.12"
    }
  }
}

# 4. Node Topology Definitions
locals {
  nodes = {
    "controlplane" = {
      vcpu   = 2
      memory = 4096
      disk   = 32212254720 # 30 GB
      mac    = "52:54:00:15:00:10"
      ip     = "192.168.150.10"
    }
    "worker-node01" = {
      vcpu   = 4
      memory = 16384
      disk   = 42949672960 # 40 GB
      mac    = "52:54:00:15:00:11"
      ip     = "192.168.150.11"
    }
    "worker-node02" = {
      vcpu   = 4
      memory = 16384
      disk   = 42949672960 # 40 GB
      mac    = "52:54:00:15:00:12"
      ip     = "192.168.150.12"
    }
  }
}

# 5. OS Disks (Differencing Disks on Base Image)
resource "libvirt_volume" "node_disks" {
  for_each       = local.nodes
  name           = "${each.key}-disk.qcow2"
  pool           = libvirt_pool.ep2_pool.name
  base_volume_id = libvirt_volume.ubuntu_base.id
  size           = each.value.disk
}

# 6. Cloud-Init ISO per Node
resource "libvirt_cloudinit_disk" "node_init" {
  for_each = local.nodes
  name     = "${each.key}-init.iso"
  pool     = libvirt_pool.ep2_pool.name
  user_data = templatefile("${path.module}/../../../cloud-init/common-k8s.cfg", {
    ssh_key = file("~/.ssh/id_ed25519.pub")
  })
}

# 7. Virtual Machine Instances
resource "libvirt_domain" "k8s_nodes" {
  for_each = local.nodes
  name     = each.key
  memory   = each.value.memory
  vcpu     = each.value.vcpu

  cloudinit = libvirt_cloudinit_disk.node_init[each.key].id

  network_interface {
    network_id     = libvirt_network.k8s_net.id
    mac            = each.value.mac
    wait_for_lease = true
  }

  disk {
    volume_id = libvirt_volume.node_disks[each.key].id
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  graphics {
    type        = "vnc"
    listen_type = "address"
  }
}
