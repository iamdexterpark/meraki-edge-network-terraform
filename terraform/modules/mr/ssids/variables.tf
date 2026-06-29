variable "network_id" {
  description = "Network ID from the network module."
  type        = string
}

variable "config" {
  description = "MR SSID configuration decoded from JSON."
  type        = any
}

variable "ssid_psks" {
  description = <<-EOT
    Map of SSID name → PSK.  Injected out-of-band (env var or secrets backend).
    Never store in JSON or commit to version control.
      export TF_VAR_ssid_psks='{"my-ssid":"secret-psk"}'
  EOT
  type        = map(string)
  sensitive   = true
  default     = {}
}
