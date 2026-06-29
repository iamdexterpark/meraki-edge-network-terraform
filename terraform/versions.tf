# ---------------------------------------------------------------------------
# Provider and version constraints.
# Compatible with both OpenTofu (>= 1.5) and Terraform (>= 1.5).
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    meraki = {
      source  = "CiscoDevNet/meraki"
      version = ">= 1.0.0"
    }
  }
}

provider "meraki" {
  # API key — prefer the environment variable:
  #   export MERAKI_DASHBOARD_API_KEY="your-key-here"
  #
  # Or supply via TF_VAR_meraki_api_key / -var / .tfvars.
  # The provider also reads MERAKI_API_KEY if set.
  api_key = var.meraki_api_key
}
