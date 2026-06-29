# ---------------------------------------------------------------------------
# Organization module
#
# Supports two modes:
#   manage = true  → creates/manages the org via meraki_organization
#   manage = false → passes through the supplied organization_id
# ---------------------------------------------------------------------------

terraform {
  required_providers {
    meraki = { source = "CiscoDevNet/meraki" }
  }
}

# Only manage the org when explicitly asked.  Most users operate inside an
# existing org and merely reference its ID, so creating/owning the org is opt-in.
resource "meraki_organization" "this" {
  count = var.config.manage ? 1 : 0

  name               = var.config.name
  management_details = try(var.config.management_details, null)
}
