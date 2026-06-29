variable "organization_id" {
  description = "Organization ID from the org module."
  type        = string
}

variable "config" {
  description = "Network configuration decoded from JSON."
  type        = any
}
