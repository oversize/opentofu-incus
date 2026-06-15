variable "incus_token" {
  description = <<-EOT
    One-time trust token from `incus config trust add <name>` on incus server.
    Required only on the first apply (or from a fresh client) to register
    this client's certificate in incus's trust store. Leave empty ("") once
    the client cert is created (stored in .incus/) which allows to authenticate
    thereafter.
  EOT
  type        = string
  default     = ""
  sensitive   = true
}
