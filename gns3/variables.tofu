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

variable "host_port" {
  description = "Port exposed on the incus host forwards to gns3_port"
  type        = number
  default     = 3080
}

variable "gns3_port" {
  description = "Port the GNS3 server listens on inside the incus container"
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
