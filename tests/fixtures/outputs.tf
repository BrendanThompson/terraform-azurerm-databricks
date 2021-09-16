output "virtual_network" {
  value = module.databricks.virtual_network.address_space[0]
}

output "virtual_network_name" {
  value = module.databricks.virtual_network.name
}

output "private_subnet" {
  value = module.databricks.private_subnet.address_prefixes[0]
}

output "private_subnet_name" {
  value = module.databricks.private_subnet.name
}

output "public_subnet" {
  value = module.databricks.public_subnet.address_prefixes[0]
}

output "public_subnet_name" {
  value = module.databricks.public_subnet.name
}

output "databricks_workspace_url" {
  value = module.databricks.databricks_workspace_url
}

output "key_vault_name" {
  value = module.databricks.key_vault.name
}

output "subscription_id" {
  value = module.databricks.subscription_id
}

output "resource_group_name" {
  value = module.databricks.resource_group.name
}
