variable "name" {
  description = "Server hostname"
  type        = string
}

variable "server_type" {
  description = "Hetzner Cloud server type"
  type        = string
  default     = "cx23"
}

variable "image" {
  description = "OS image to use"
  type        = string
  default     = "debian-10"
}

variable "location" {
  description = "Hetzner Cloud datacenter location"
  type        = string
  default     = "nbg1"
}

variable "backups" {
  description = "Enable automatic backups"
  type        = bool
  default     = true
}

variable "delete_protection" {
  description = "Enable delete protection"
  type        = bool
  default     = true
}

variable "rebuild_protection" {
  description = "Enable rebuild protection"
  type        = bool
  default     = true
}

variable "ssh_key_ids" {
  description = "IDs of existing hcloud_ssh_key resources"
  type        = list(string)
  default     = []
}

variable "labels" {
  description = "Labels to attach to the server"
  type        = map(string)
  default     = {}
}
