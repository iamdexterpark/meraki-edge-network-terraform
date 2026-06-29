output "organization_id" {
  description = "The organization ID — managed resource ID or the supplied ID."
  value       = var.config.manage ? meraki_organization.this[0].id : var.config.organization_id
}
