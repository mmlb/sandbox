output "provisioner_ip" {
  value = metal_device.tink_provisioner.network[0].address
}

output "provisioner_ssh" {
  value = format("%s.packethost.net", split("-", metal_device.tink_provisioner.id)[0])
}

output "worker_sos_destinations" {
  value = formatlist("%s@sos.%s.platformequinix.com", metal_device.tink_worker[*].id, metal_device.tink_worker.deployed_facility)
}

output "worker_macs" {
  #value = flatten([for wp in metal_device.tink_worker[*].ports[*] : [for p in wp : p.mac if p.name == "eth1"]])
  value = local.worker_macs
}
