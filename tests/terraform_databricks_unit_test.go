//go:build unit

package test

import (
	"regexp"
	"strconv"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/assert"
)

const (
	fixtures = "./fixtures"
)

func TestAzureResources(t *testing.T) {
	opts := &terraform.Options{
		TerraformDir: fixtures,
		NoColor:      true,
	}

	plan := terraform.InitAndPlan(t, opts)

	assert.NotEmpty(t, plan)

	re := regexp.MustCompile(`Plan: (\d+) to add, (\d+) to change, (\d+) to destroy.`)
	planResult := re.FindStringSubmatch(plan)

	testCases := []struct {
		name string
		got  string
		want int
	}{
		{"created", planResult[1], 13},
		{"changed", planResult[2], 0},
		{"destroyed", planResult[3], 0},
	}

	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			got, err := strconv.Atoi(tc.got)
			if err != nil {
				t.Errorf("Unable to convert string to int")
			}
			assert.Equal(t, got, tc.want)
		})
	}
}
