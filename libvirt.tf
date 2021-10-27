provider "libvirt" {
  uri = "qemu:///system"
}

locals {
  nodes = concat(formatlist("tmp-alp-controller-%d", range(var.controller_nodes)), formatlist("tmp-alp-worker-%d", range(var.worker_nodes)))
}

resource "libvirt_pool" "alpine-cloud" {
  name = "alpine"
  type = "dir"
  path = "/var/tmp/terraform-provider-libvirt-pool-alpine"
}

resource "libvirt_volume" "alpine-qcow2" {
  for_each = toset(local.nodes)
  name = "${each.value}-qcow2"
  pool = libvirt_pool.alpine-cloud.name
  source = "./alpine-cloud.img"
  format = "qcow2"
}

data "template_file" "meta_data" {
  for_each = toset(local.nodes)
  template = file("${path.module}/meta-data")
  vars = { hostname = each.value }
}
resource "libvirt_cloudinit_disk" "seed" {
  for_each = toset(local.nodes)
  name      = "seed-${each.value}.iso"
  meta_data = data.template_file.meta_data[each.value].rendered
  pool      = libvirt_pool.alpine-cloud.name
}

resource "libvirt_domain" "k0s-node" {
  for_each = toset(local.nodes)
  name   = each.value
  memory = var.memory
  vcpu   = var.vcpu

  cloudinit = libvirt_cloudinit_disk.seed[each.value].id

  network_interface {
    network_name = "default"
  }

  disk {
    volume_id = libvirt_volume.alpine-qcow2[each.value].id
  }

  console {
    type        = "pty"
    target_type = "serial"
    target_port = "0"
  }
  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }
}

# generate a file with the list of all nodes so we can get fish out the ip addresses
resource "local_file" "nodelist" {
  content = join("\n", local.nodes)
  filename = "${path.module}/nodelist.txt"
}
