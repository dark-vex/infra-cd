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
  default     = 1
}

variable "cpu_sockets" {
  description = "Number of CPU sockets"
  type        = number
  default     = 1
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
  description = "Mappa dei dischi virtuali"
  # La chiave della mappa sarà un nome logico (es. 'boot', 'storage')
  type = map(object({
    datastore_id = string
    interface    = string # Es. scsi0, scsi1 (FONDAMENTALE che sia univoco)
    size         = number
    file_format  = optional(string, "raw")
    file_id      = optional(string)
    iothread     = optional(bool, true)
    ssd          = optional(bool, true)
    discard      = optional(string, "on")
  }))
  default = {}
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

variable "network_disconnected" {
  description = "Whether the network interface is disconnected"
  type        = bool
  default     = false
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

variable "cloud_init_dns" {
  description = "Cloud-init DNS configuration"
  type = object({
    domain  = optional(string)
    servers = optional(list(string))
  })
  default = {}
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

variable "bios_type" {
  description = "BIOS type"
  type        = string
  default     = "seabios"
}

variable "protection" {
  description = "Enable VM protection to prevent accidental deletion"
  type = bool
  default = false
}

variable "efi_disk" {
  type = object({
    datastore_id      = string
    file_format       = optional(string)
    type              = optional(string)
    pre_enrolled_keys = optional(bool)
  })
  default = null
}

variable "cdrom" {
  description = "Configurazione del CD-ROM"
  type = object({
    file_id   = string
    interface = optional(string, "ide2")
  })
  default = null
}

variable "cloud_init_datastore_id" {
  description = "Datastore per il disco Cloud-Init. Se null, Cloud-Init viene disabilitato."
  type        = string
  default     = null 
}

variable "boot_order" {
  description = "Boot order (es. 'cdn' per CD-ROM, disco, network)"
  type        = list(string)
  default     = ["scsi0"]
}