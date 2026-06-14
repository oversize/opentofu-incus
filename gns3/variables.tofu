variable "container_name" {
  description = "Name of the GNS3 Incus container"
  type        = string
  default     = "gns3"
}

variable "container_image" {
  description = "Incus image for the container. Must be a /cloud variant for cloud-init support."
  type        = string
  default     = "images:debian/13/cloud"
}

variable "container_cpus" {
  description = "Number of vCPUs to allocate"
  type        = number
  default     = 4
}

variable "container_memory" {
  description = "Memory limit (Incus size notation)"
  type        = string
  default     = "8GiB"
}

variable "container_disk" {
  description = "Root disk size (Incus size notation)"
  type        = string
  default     = "50GiB"
}

variable "kvm_module" {
  description = "Host KVM kernel module name. kvm_intel for Intel CPUs, kvm_amd for AMD."
  type        = string
  default     = "kvm_amd"

  validation {
    condition     = contains(["kvm_intel", "kvm_amd"], var.kvm_module)
    error_message = "kvm_module must be either kvm_intel or kvm_amd."
  }
}

variable "gns3_port" {
  description = "Port the GNS3 server listens on inside the container"
  type        = number
  default     = 3080
}

variable "host_port" {
  description = "Port exposed on the odin host that forwards to gns3_port"
  type        = number
  default     = 3080
}

variable "gns3_user" {
  description = "GNS3 server auth username"
  type        = string
  default     = "gns3admin"
}

variable "gns3_password" {
  description = "GNS3 server auth password"
  type        = string
  sensitive   = true
}

variable "gns3_version" {
  description = "GNS3 major version string, used for config directory path inside container"
  type        = string
  default     = "2.2"
}

variable "container_user" {
  description = "OS user inside the container that runs the GNS3 daemon"
  type        = string
  default     = "gns3"
}

variable "storage_pool" {
  description = "Incus storage pool name for the root disk"
  type        = string
  default     = "default"
}

variable "network_name" {
  description = "Incus managed bridge network to attach the container to"
  type        = string
  default     = "incusbr0"
}

# ── Remote HTTPS connection to odin ─────────────────────────────────────────

variable "incus_address" {
  description = "IP address or hostname of odin (the Incus server). No scheme, no port."
  type        = string
  # e.g. "192.168.1.50" or "odin.lan"
}

variable "incus_bootstrap_token" {
  description = <<-EOT
    One-time trust token from `incus config trust add <name>` on odin.
    Required only on the first apply (or from a fresh client) to register
    this client's certificate in odin's trust store. Leave empty ("") once
    the client cert is trusted — the persisted cert authenticates thereafter.
  EOT
  type        = string
  default     = ""
  sensitive   = true
}
