mock_provider "azurerm" {}

override_data {
  target = data.azurerm_client_config.current
  values = {
    tenant_id       = "00000000-0000-0000-0000-000000000000"
    subscription_id = "00000000-0000-0000-0000-000000000000"
  }
}

variables {
  resource_group_name = "rg-test-core"
  location            = "westeurope"

  key_vault = {
    name = "kv-test-core"
  }

  tags = {
    Environment = "Test"
  }
}

run "creates_resource_group" {
  command = plan

  assert {
    condition     = azurerm_resource_group.this.name == "rg-test-core"
    error_message = "Resource group name does not match expected value."
  }

  assert {
    condition     = azurerm_resource_group.this.location == "westeurope"
    error_message = "Resource group location does not match expected value."
  }

  assert {
    condition     = azurerm_resource_group.this.tags["Environment"] == "Test"
    error_message = "Custom tags should be merged into the resource group tags."
  }
}

run "creates_key_vault" {
  command = plan

  assert {
    condition     = output.key_vault_name == "kv-test-core"
    error_message = "Key vault name does not match expected value."
  }
}

run "creates_cmk_keys_by_default" {
  command = plan

  assert {
    condition     = output.cmkrsa_key_name == "cmkrsa"
    error_message = "cmkrsa_key_name output should default to 'cmkrsa' when cmk_keys_create is not overridden."
  }
}

run "cmk_keys_not_created_when_disabled" {
  command = plan

  variables {
    key_vault = {
      name            = "kv-test-core"
      cmk_keys_create = false
    }
  }

  assert {
    condition     = output.cmkrsa_key_name == null
    error_message = "cmkrsa_key_name output should be null when cmk_keys_create is false."
  }
}

run "recovery_services_vault_not_created_by_default" {
  command = plan

  assert {
    condition     = length(module.recovery_services_vault) == 0
    error_message = "Recovery services vault module should not be created when recovery_services_vault is null."
  }

  assert {
    condition     = output.recovery_services_vault_id == null
    error_message = "recovery_services_vault_id output should be null when recovery services vault is not configured."
  }
}

run "recovery_services_vault_created_when_configured" {
  command = plan

  variables {
    recovery_services_vault = {
      name = "rsv-test-core"
    }
  }

  assert {
    condition     = length(module.recovery_services_vault) == 1
    error_message = "Recovery services vault module should be created when recovery_services_vault is set."
  }
}

run "container_registry_not_created_by_default" {
  command = plan

  assert {
    condition     = length(module.container_registry) == 0
    error_message = "Container registry module should not be created when container_registry is null."
  }

  assert {
    condition     = output.container_registry_id == null
    error_message = "container_registry_id output should be null when container registry is not configured."
  }
}

run "container_registry_created_when_configured" {
  command = plan

  variables {
    container_registry = {
      name                          = "acrtestcore001"
      public_network_access_enabled = true
    }
  }

  assert {
    condition     = length(module.container_registry) == 1
    error_message = "Container registry module should be created when container_registry is set."
  }
}

run "container_registry_private_endpoint_when_pe_subnet_set" {
  command = plan

  variables {
    container_registry = {
      name      = "acrtestcore002"
      pe_subnet = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test-core/providers/Microsoft.Network/virtualNetworks/vnet-test-core/subnets/snet-test-core"
    }
  }

  assert {
    condition     = length(module.container_registry) == 1
    error_message = "Container registry module should be created when container_registry is set, even with public network access disabled and a pe_subnet configured."
  }
}
