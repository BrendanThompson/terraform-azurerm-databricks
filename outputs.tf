output "databricks_workspace_url" {
  value = azurerm_databricks_workspace.this.workspace_url
}

output "key_vault" {
  value = azurerm_key_vault.this
}

output "virtual_network" {
  value = azurerm_virtual_network.this
}

output "private_subnet" {
  value = azurerm_subnet.private
}

output "public_subnet" {
  value = azurerm_subnet.public
}

output "resource_group" {
  value = azurerm_resource_group.this
}

output "subscription_id" {
  value = data.azurerm_client_config.current.subscription_id
}
