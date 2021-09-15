//go:build integration

package test

import (
	"testing"

	"github.com/gruntwork-io/terratest/modules/azure"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

const (
	fixtures = "./fixtures"
)

type TestCondition int

const (
	TestConditionEquals   TestCondition = 0
	TestConditionNotEmpty TestCondition = 1
)

func TestDatabricks(t *testing.T) {
	terraform.InitAndApply(t, IntegrationTestOptions())
	defer terraform.Destroy(t, IntegrationTestOptions())

	t.Run("Output Validation", OutputValidation)
	t.Run("Key Vault Validation", KeyVaultValidation)
	t.Run("Networks", Networks)
}

func OutputValidation(t *testing.T) {
	testCases := []struct {
		Name      string
		Got       string
		Want      string
		Condition TestCondition
	}{
		{"Virtual Network Range", terraform.Output(t, IntegrationTestOptions(), "virtual_network"), "10.0.0.0/23", TestConditionEquals},
		{"Private Subnet Range", terraform.Output(t, IntegrationTestOptions(), "private_subnet"), "10.0.0.0/24", TestConditionEquals},
		{"Public Subnet Range", terraform.Output(t, IntegrationTestOptions(), "public_subnet"), "10.0.1.0/24", TestConditionEquals},
		{"Workspace URL", terraform.Output(t, IntegrationTestOptions(), "databricks_workspace_url"), "", TestConditionNotEmpty},
	}

	for _, tc := range testCases {
		t.Run(tc.Name, func(t *testing.T) {
			switch tc.Condition {
			case TestConditionEquals:
				assert.Equal(t, tc.Got, tc.Want)
			case TestConditionNotEmpty:
				assert.NotEmpty(t, tc.Got)
			}

		})
	}
}

func KeyVaultValidation(t *testing.T) {
	name := terraform.Output(t, IntegrationTestOptions(), "key_vault_name")
	subscriptionID := terraform.Output(t, IntegrationTestOptions(), "subscription_id")
	resourceGroup := terraform.Output(t, IntegrationTestOptions(), "resource_group_name")
	keyVault := azure.GetKeyVault(t, resourceGroup, name, subscriptionID)

	t.Log(name)
	t.Log(subscriptionID)
	t.Log(resourceGroup)
	t.Log(keyVault)

	t.Run("Key Vault Exists", func(t *testing.T) {
		assert.Equal(t, *keyVault.Name, name)
	})

	t.Run("Key Vault Secret Exists", func(t *testing.T) {
		assert.True(t, azure.KeyVaultKeyExists(t, name, "cmk"))
	})
}

func Networks(t *testing.T) {
	virtualNetworkName := terraform.Output(t, IntegrationTestOptions(), "virtual_network_name")
	privateSubnetName := terraform.Output(t, IntegrationTestOptions(), "private_subnet_name")
	publicSubnetName := terraform.Output(t, IntegrationTestOptions(), "public_subnet_name")
	resourceGroupName := terraform.Output(t, IntegrationTestOptions(), "resource_group_name")
	subscriptionID := terraform.Output(t, IntegrationTestOptions(), "subscription_id")

	t.Run("Private Subnet Delegations", func(t *testing.T) {
		privateSubnet, err := azure.GetSubnetE(privateSubnetName, virtualNetworkName, resourceGroupName, subscriptionID)
		if err != nil {
			t.Fatal(err)
		}

		for _, p := range *privateSubnet.SubnetPropertiesFormat.Delegations {
			assert.Equal(t, *p.ServiceDelegationPropertiesFormat.ServiceName, "Microsoft.Databricks/workspaces")
		}
	})

	t.Run("Public Subnet Delegations", func(t *testing.T) {
		publicSubnet, err := azure.GetSubnetE(publicSubnetName, virtualNetworkName, resourceGroupName, subscriptionID)
		if err != nil {
			t.Fatal(err)
		}

		t.Log(*publicSubnet.Name)
		for _, p := range *publicSubnet.SubnetPropertiesFormat.Delegations {
			assert.Equal(t, *p.ServiceDelegationPropertiesFormat.ServiceName, "Microsoft.Databricks/workspaces")
		}
	})
}

func IntegrationTestOptions() *terraform.Options {
	return &terraform.Options{
		TerraformDir: fixtures,
		NoColor:      true,
	}
}
