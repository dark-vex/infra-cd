variable "display_name" {
  description = "Display name for the instance"
  type        = string
}

variable "compartment_id" {
  description = "OCID of the compartment in which to create the instance"
  type        = string
}

variable "availability_domain" {
  description = "Availability domain for the instance"
  type        = string
}

variable "shape" {
  description = "Instance shape (e.g. VM.Standard.A1.Flex for Ampere)"
  type        = string
  default     = "VM.Standard.A1.Flex"
}

variable "ocpus" {
  description = "Number of OCPUs (for Flex shapes)"
  type        = number
  default     = 4
}

variable "memory_in_gbs" {
  description = "Memory in GBs (for Flex shapes)"
  type        = number
  default     = 24
}

variable "image_id" {
  description = "OCID of the OS image"
  type        = string
}

variable "subnet_id" {
  description = "OCID of the subnet to attach the instance to"
  type        = string
}

variable "ssh_authorized_keys" {
  description = "SSH public key(s) to inject into the instance"
  type        = string
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP"
  type        = bool
  default     = true
}

variable "boot_volume_size_in_gbs" {
  description = "Boot volume size in GBs"
  type        = number
  default     = 50
}

variable "freeform_tags" {
  description = "Freeform tags for the instance"
  type        = map(string)
  default     = {}
}
