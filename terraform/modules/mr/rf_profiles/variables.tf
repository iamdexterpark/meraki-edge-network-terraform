variable "network_id" {
  description = "Network ID from the network module."
  type        = string
}

variable "config" {
  description = "MR RF profiles configuration decoded from JSON."
  type        = any
}
