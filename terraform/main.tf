# ---------------------------------------------------------------------------
# Root composition — Meraki Edge Network
#
# Dependency chain (matches Meraki Dashboard hierarchy):
#
#   1. Organization
#   2. Network
#   3. Device Claims
#   4. Device Settings  (MX settings, MS settings, MR settings)
#   5. Device Features  (VLANs, Firewall, Ports, SSIDs, etc.)
#
# Each module reads its configuration from a JSON file under var.config_path.
# Copy config.example/ to config/ and edit for your environment.
# ---------------------------------------------------------------------------

locals {
  cfg = var.config_path

  # --- Load JSON configs (use try() so missing files don't break plan) ---
  org_config     = jsondecode(file("${local.cfg}/org/organization.json"))
  network_config = jsondecode(file("${local.cfg}/network/network.json"))
  devices_config = try(jsondecode(file("${local.cfg}/devices/devices.json")), { serials = [], devices = [] })

  # MX configs
  mx_settings_config        = try(jsondecode(file("${local.cfg}/mx/settings.json")), { vlans_enabled = true })
  mx_vlans_config           = try(jsondecode(file("${local.cfg}/mx/vlans.json")), { vlans = [] })
  mx_firewall_config        = try(jsondecode(file("${local.cfg}/mx/firewall.json")), {})
  mx_vpn_config             = try(jsondecode(file("${local.cfg}/mx/vpn.json")), {})
  mx_routing_config         = try(jsondecode(file("${local.cfg}/mx/routing.json")), { static_routes = [] })
  mx_ports_config           = try(jsondecode(file("${local.cfg}/mx/ports.json")), { ports = [] })
  mx_traffic_shaping_config = try(jsondecode(file("${local.cfg}/mx/traffic_shaping.json")), {})

  # MS configs
  ms_settings_config = try(jsondecode(file("${local.cfg}/ms/settings.json")), null)
  ms_ports_config    = try(jsondecode(file("${local.cfg}/ms/ports.json")), { ports = [] })
  ms_qos_config      = try(jsondecode(file("${local.cfg}/ms/qos.json")), { qos_rules = [] })
  ms_routing_config  = try(jsondecode(file("${local.cfg}/ms/routing.json")), {})
  ms_stp_config      = try(jsondecode(file("${local.cfg}/ms/stp.json")), null)
  ms_acl_config      = try(jsondecode(file("${local.cfg}/ms/acl.json")), null)

  # MR configs
  mr_settings_config    = try(jsondecode(file("${local.cfg}/mr/settings.json")), {})
  mr_ssids_config       = try(jsondecode(file("${local.cfg}/mr/ssids.json")), { ssids = [] })
  mr_rf_profiles_config = try(jsondecode(file("${local.cfg}/mr/rf_profiles.json")), { rf_profiles = [] })
}

# =====================================================================
# 1. Organization
# =====================================================================
module "org" {
  source = "./modules/org"
  config = local.org_config
}

# =====================================================================
# 2. Network
# =====================================================================
module "network" {
  source          = "./modules/network"
  organization_id = module.org.organization_id
  config          = local.network_config
}

# =====================================================================
# 3. Device Claims
# =====================================================================
module "devices" {
  source     = "./modules/devices"
  network_id = module.network.network_id
  config     = local.devices_config
}

# =====================================================================
# 4a. MX Appliance — Settings (must run before VLANs)
# =====================================================================
module "mx_settings" {
  source     = "./modules/mx/settings"
  network_id = module.network.network_id
  config     = local.mx_settings_config

  depends_on = [module.devices]
}

# =====================================================================
# 4b. MX Appliance — VLANs (depends on MX settings enabling VLANs)
# =====================================================================
module "mx_vlans" {
  source     = "./modules/mx/vlans"
  network_id = module.network.network_id
  config     = local.mx_vlans_config

  depends_on = [module.mx_settings]
}

# =====================================================================
# 4c. MX Appliance — Firewall (L3 + L7 rules)
# =====================================================================
module "mx_firewall" {
  source     = "./modules/mx/firewall"
  network_id = module.network.network_id
  config     = local.mx_firewall_config

  depends_on = [module.mx_vlans]
}

# =====================================================================
# 4d. MX Appliance — VPN (site-to-site, BGP)
# =====================================================================
module "mx_vpn" {
  source     = "./modules/mx/vpn"
  network_id = module.network.network_id
  config     = local.mx_vpn_config

  depends_on = [module.mx_vlans]
}

# =====================================================================
# 4e. MX Appliance — Routing (static routes)
# =====================================================================
module "mx_routing" {
  source     = "./modules/mx/routing"
  network_id = module.network.network_id
  config     = local.mx_routing_config

  depends_on = [module.mx_vlans]
}

# =====================================================================
# 4f. MX Appliance — Ports
# =====================================================================
module "mx_ports" {
  source     = "./modules/mx/ports"
  network_id = module.network.network_id
  config     = local.mx_ports_config

  depends_on = [module.mx_settings]
}

# =====================================================================
# 4g. MX Appliance — Traffic Shaping / QoS
# =====================================================================
module "mx_traffic_shaping" {
  source     = "./modules/mx/traffic_shaping"
  network_id = module.network.network_id
  config     = local.mx_traffic_shaping_config

  depends_on = [module.mx_vlans]
}

# =====================================================================
# 5a. MS Switch — Settings
# =====================================================================
module "ms_settings" {
  source     = "./modules/ms/settings"
  network_id = module.network.network_id
  config     = local.ms_settings_config

  depends_on = [module.devices]
}

# =====================================================================
# 5b. MS Switch — Ports
# =====================================================================
module "ms_ports" {
  source     = "./modules/ms/ports"
  network_id = module.network.network_id
  config     = local.ms_ports_config

  depends_on = [module.ms_settings]
}

# =====================================================================
# 5c. MS Switch — QoS
# =====================================================================
module "ms_qos" {
  source     = "./modules/ms/qos"
  network_id = module.network.network_id
  config     = local.ms_qos_config

  depends_on = [module.ms_settings]
}

# =====================================================================
# 5d. MS Switch — Routing (L3 interfaces, static routes, OSPF)
# =====================================================================
module "ms_routing" {
  source     = "./modules/ms/routing"
  network_id = module.network.network_id
  config     = local.ms_routing_config

  depends_on = [module.ms_settings]
}

# =====================================================================
# 5e. MS Switch — STP
# =====================================================================
module "ms_stp" {
  source     = "./modules/ms/stp"
  network_id = module.network.network_id
  config     = local.ms_stp_config

  depends_on = [module.ms_settings]
}

# =====================================================================
# 5f. MS Switch — ACLs
# =====================================================================
module "ms_acl" {
  source     = "./modules/ms/acl"
  network_id = module.network.network_id
  config     = local.ms_acl_config

  depends_on = [module.ms_settings]
}

# =====================================================================
# 6a. MR Wireless — Settings
# =====================================================================
module "mr_settings" {
  source     = "./modules/mr/settings"
  network_id = module.network.network_id
  config     = local.mr_settings_config

  depends_on = [module.devices]
}

# =====================================================================
# 6b. MR Wireless — SSIDs
# =====================================================================
module "mr_ssids" {
  source     = "./modules/mr/ssids"
  network_id = module.network.network_id
  config     = local.mr_ssids_config
  ssid_psks  = var.ssid_psks # PSKs injected out-of-band; never sourced from JSON

  depends_on = [module.mr_settings]
}

# =====================================================================
# 6c. MR Wireless — RF Profiles
# =====================================================================
module "mr_rf_profiles" {
  source     = "./modules/mr/rf_profiles"
  network_id = module.network.network_id
  config     = local.mr_rf_profiles_config

  depends_on = [module.mr_settings]
}
