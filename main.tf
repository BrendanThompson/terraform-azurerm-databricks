data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "this" {
  name     = format("rg-%s", var.suffix)
  location = var.location
}

resource "azurerm_virtual_network" "this" {
  name = format("vn-%s", var.suffix)

  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  address_space = [var.network.range]
}

resource "azurerm_subnet" "private" {
  name = format("sn-%s-priv", var.suffix)

  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.network.private_subnet]

  delegation {
    name = "databricks-delegation"

    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

resource "azurerm_network_security_group" "private" {
  name = format("nsg-%s-priv", var.suffix)

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}

resource "azurerm_subnet_network_security_group_association" "private" {
  subnet_id                 = azurerm_subnet.private.id
  network_security_group_id = azurerm_network_security_group.private.id
}

resource "azurerm_subnet" "public" {
  name = format("sn-%s-pub", var.suffix)

  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [var.network.public_subnet]

  delegation {
    name = "databricks-delegation"

    service_delegation {
      name = "Microsoft.Databricks/workspaces"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/join/action",
        "Microsoft.Network/virtualNetworks/subnets/prepareNetworkPolicies/action",
        "Microsoft.Network/virtualNetworks/subnets/unprepareNetworkPolicies/action",
      ]
    }
  }
}

resource "azurerm_network_security_group" "public" {
  name = format("nsg-%s-pub", var.suffix)

  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
}

resource "azurerm_subnet_network_security_group_association" "public" {
  subnet_id                 = azurerm_subnet.public.id
  network_security_group_id = azurerm_network_security_group.public.id
}

resource "azurerm_key_vault" "this" {
  name                = format("kv-%s", var.suffix)
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  tenant_id           = data.azurerm_client_config.current.tenant_id

  sku_name = var.key_vault.sku_name
}

resource "azurerm_key_vault_key" "this" {
  name         = "cmk"
  key_vault_id = azurerm_key_vault.this.id
  key_type     = "RSA"
  key_size     = 4096

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  depends_on = [
    azurerm_key_vault_access_policy.terraform
  ]
}



resource "azurerm_key_vault_access_policy" "terraform" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = azurerm_key_vault.this.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "get",
    "list",
    "create",
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
    "delete",
    "restore",
    "recover",
    "update",
    "purge",
  ]
}

// NOTE: This is a static Object ID as it's managed by Microsoft
resource "azurerm_key_vault_access_policy" "managed" {
  key_vault_id = azurerm_key_vault.this.id
  tenant_id    = azurerm_key_vault.this.tenant_id
  object_id    = "29cb0b2d-4679-4068-af52-d59876271057"

  key_permissions = [
    "get",
    "unwrapKey",
    "wrapKey",
  ]
}

resource "azurerm_databricks_workspace" "this" {
  name                = format("dbs-%s", var.suffix)
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "premium"

  managed_services_cmk_key_vault_key_id = azurerm_key_vault_key.this.id

  custom_parameters {
    virtual_network_id                                   = azurerm_virtual_network.this.id
    private_subnet_name                                  = azurerm_subnet.private.name
    public_subnet_name                                   = azurerm_subnet.public.name
    private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.private.id
    public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.public.id
  }

  depends_on = [
    azurerm_key_vault_access_policy.managed
  ]
}
