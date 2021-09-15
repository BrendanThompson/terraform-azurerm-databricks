provider "azurerm" {
  features {}
}

module "databricks" {
  source = "../../"

  suffix = "aue-dev-blt"
}
