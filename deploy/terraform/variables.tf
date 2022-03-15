variable "metal_api_token" {
  description = "Equinix Metal user api token"
  type        = string
}

variable "project_id" {
  description = "Project ID"
  type        = string
}

variable "facility" {
  description = "Packet facility to provision in"
  type        = string
  default     = "sjc1"
}

variable "device_type" {
  type        = string
  description = "Type of device to provision"
  default     = "c3.small.x86"
}

variable "use_ssh_agent" {
  type        = bool
  description = "Use ssh agent to connect to provisioner machine"
  default     = false
}

variable "ssh_private_key" {
  type        = string
  description = "ssh private key file to use"
  default     = "~/.ssh/id_rsa"
}

variable "hostname_prefix" {
  description = "Prefix to prepend to hostname of provisioned machines"
  type        = string
  default     = "tink"
}
