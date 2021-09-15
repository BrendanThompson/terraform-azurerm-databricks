variable "location" {
  type        = string
  description = <<-EOF
		(Optional) Location where the resources will be provisioned.
		[Default: australiaeast]
	EOF
  default     = "australiaeast"
}

variable "suffix" {
  type        = string
  description = <<-EOF
		(Required) A suffix for the name of the resources.
	EOF
}

variable "key_vault" {
  type = object({
    sku_name = string
  })
  description = <<-EOF
		(Optional) Required parameters to create a Key Vault for Databricks

		sku_name: The SKU name of the Key Vault to create. [Default: standard]
	EOF
  default = {
    sku_name = "standard"
  }

  validation {
    condition     = can(regex("standard|premium", var.key_vault.sku_name))
    error_message = "Invalid option for Key Vault SKU."
  }
}

variable "network" {
  type = object({
    range          = string
    private_subnet = string
    public_subnet  = string
  })
  description = <<-EOF
		(Optional) The network configuration of the Databricks cluster to create.

		range: The range of the subnet to create. [Default: 10.0.0.0/23]
		private_subnet: The name of the private subnet to create. [Default: 10.0.0.0/24]
		public_subnet: The name of the public subnet to create. [Default: 10.0.1.0/24]
	EOF
  default = {
    range          = "10.0.0.0/23"
    private_subnet = "10.0.0.0/24"
    public_subnet  = "10.0.1.0/24"
  }
}
