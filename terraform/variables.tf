# ---------------------------------------------------------------------------
# Root variables — intentionally minimal.
# All network/device/feature configuration lives in JSON files under
# the config_path directory.  See config.example/ for reference.
# ---------------------------------------------------------------------------

variable "meraki_api_key" {
  description = <<-EOT
    Meraki Dashboard API key.
    Prefer environment variables — never commit this value:
      export MERAKI_DASHBOARD_API_KEY="..."   (provider reads this directly)
      export TF_VAR_meraki_api_key="..."      (Terraform injects it)
  EOT
  type        = string
  sensitive   = true
  default     = null # Falls back to MERAKI_DASHBOARD_API_KEY env var
}

variable "config_path" {
  description = <<-EOT
    Path to the directory containing JSON configuration files.
    Defaults to ./config relative to the root module.
    Copy config.example/ to config/ and edit for your environment.
  EOT
  type        = string
  default     = "./config"
}

variable "ssid_psks" {
  description = <<-EOT
    Map of SSID name -> pre-shared key. Injected out-of-band, never from JSON
    and never committed:
      export TF_VAR_ssid_psks='{"edge-trusted":"...","edge-iot":"..."}'
    The mr/ssids module looks up each PSK by SSID name; an SSID whose authMode
    is not "psk" ignores this entirely.
  EOT
  type        = map(string)
  sensitive   = true
  default     = {}
}
