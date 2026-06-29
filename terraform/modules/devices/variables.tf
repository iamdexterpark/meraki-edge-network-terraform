variable "network_id" {
  description = "Network ID from the network module."
  type        = string
}

variable "config" {
  description = "Devices configuration decoded from JSON."
  type        = any
}
