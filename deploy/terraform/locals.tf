locals {
  worker_macs = flatten([for wp in metal_device.tink_worker[*].ports[*] : [for p in wp : p.mac if p.name == "eth0"]])
}
