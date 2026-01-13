variable "hostname" {
  description = "Container hostname"
  type        = string
}

variable "vmid" {
  description = "Container ID"
  type        = number
}

variable "node_name" {
  description = "Target Proxmox node name"
  type        = string
}

variable "description" {
  description = "Container description"
  type        = string
  default     = ""
}

variable "cpu_cores" {
  description = "Number of CPU cores"
  type        = number
  default     = 1
}

variable "cpu_architecture" {
  description = "CPU architecture"
  type        = string
  default     = "amd64"
}

variable "memory" {
  description = "Memory in MB"
  type        = number
  default     = 512
}

variable "swap" {
  description = "Swap in MB"
  type        = number
  default     = 0
}

variable "disk_size" {
  description = "Root disk size in GB"
  type        = number
  default     = 8
}

variable "disk_datastore" {
  description = "Datastore for root disk"
  type        = string
  default     = "local-lvm"
}

variable "template_file_id" {
  description = "LXC template file ID"
  type        = string
}

variable "os_type" {
  description = "Operating system type (ubuntu, debian, centos, etc.)"
  type        = string
  default     = "ubuntu"
}

variable "network_bridge" {
  description = "Network bridge name"
  type        = string
  default     = "vmbr0"
}

variable "network_interface_name" {
  description = "Network interface name inside container"
  type        = string
  default     = "eth0"
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

variable "password" {
  description = "Root password"
  type        = string
  default     = null
  sensitive   = true
}

variable "unprivileged" {
  description = "Run as unprivileged container"
  type        = bool
  default     = true
}

variable "tags" {
  description = "Resource tags"
  type        = list(string)
  default     = ["automation", "lxc"]
}

variable "started" {
  description = "Whether container should be started after creation"
  type        = bool
  default     = true
}

variable "start_on_boot" {
  description = "Whether container should start on host boot"
  type        = bool
  default     = true
}

variable "startup_order" {
  description = "Startup order (lower = earlier)"
  type        = number
  default     = 10
}

variable "startup_up_delay" {
  description = "Startup delay in seconds"
  type        = number
  default     = 60
}

variable "startup_down_delay" {
  description = "Shutdown delay in seconds"
  type        = number
  default     = 60
}

variable "features" {
  description = "Container features"
  type = object({
    nesting = optional(bool, false)
    fuse    = optional(bool, false)
    keyctl  = optional(bool, false)
    mount   = optional(list(string), [])
  })
  default = {}
}

variable "mount_points" {
  description = "Additional mount points"
  type = list(object({
    volume    = string
    path      = string
    size      = optional(string)
    quota     = optional(bool, false)
    replicate = optional(bool, false)
    shared    = optional(bool, false)
  }))
  default = []
}
