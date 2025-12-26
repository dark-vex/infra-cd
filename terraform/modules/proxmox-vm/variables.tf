variable "name" {
  description = "VM name/hostname"
  type        = string
}

variable "vmid" {
  description = "VM ID"
  type        = number
}

variable "node_name" {
  description = "Target Proxmox node name"
  type        = string
}

variable "description" {
  description = "VM description"
  type        = string
  default     = ""
}

variable "cpu_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 2
}

variable "cpu_type" {
  description = "CPU type (e.g., host, x86-64-v2-AES)"
  type        = string
  default     = "host"
}

variable "cpu_architecture" {
  description = "CPU architecture"
  type        = string
  default     = "x86_64"
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 2048
}

variable "disks" {
  description = "List of disk configurations"
  type = list(object({
    datastore_id = string
    size         = number
    interface    = optional(string, "virtio0")
    file_format  = optional(string, "raw")
    file_id      = optional(string)
    iothread     = optional(bool, true)
  }))
  default = []
}

variable "network_bridge" {
  description = "Network bridge name"
  type        = string
  default     = "vmbr0"
}

variable "network_mac_address" {
  description = "MAC address for network interface (optional)"
  type        = string
  default     = null
}

variable "ip_config" {
  description = "IP configuration"
  type = object({
    ipv4_address = optional(string, "dhcp")
    ipv4_gateway = optional(string)
    ipv6_address = optional(string)
    ipv6_gateway = optional(string)
  })
  default = {
    ipv4_address = "dhcp"
  }
}

variable "ssh_keys" {
  description = "List of SSH public keys"
  type        = list(string)
  default     = []
}

variable "cloud_init_user" {
  description = "Cloud-init username"
  type        = string
  default     = "ubuntu"
}

variable "cloud_init_password" {
  description = "Cloud-init password"
  type        = string
  default     = null
  sensitive   = true
}

variable "cloud_init_file_id" {
  description = "Cloud-init user data file ID"
  type        = string
  default     = null
}

variable "cloud_init_datastore_id" {
  description = "Datastore for cloud-init drive"
  type        = string
  default     = "local-lvm"
}

variable "tags" {
  description = "Resource tags"
  type        = list(string)
  default     = ["automation"]
}

variable "started" {
  description = "Whether VM should be started after creation"
  type        = bool
  default     = true
}

variable "start_on_boot" {
  description = "Whether VM should start on host boot"
  type        = bool
  default     = true
}

variable "agent_enabled" {
  description = "Enable QEMU guest agent"
  type        = bool
  default     = true
}

variable "os_type" {
  description = "Operating system type"
  type        = string
  default     = "l26" # Linux 2.6+ kernel
}
