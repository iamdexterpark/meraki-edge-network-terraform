variable "network_id" {
  description = "Network ID from the network module."
  type        = string
}

variable "config" {
  description = "MX firewall configuration decoded from JSON. Expected keys: l3_firewall_rules, l7_firewall_rules."
  type        = any
}
