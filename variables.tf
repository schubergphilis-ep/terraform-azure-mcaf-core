variable "resource_group_name" {
  description = "The name of the resource group in which to create the resources."
  type        = string
}

variable "location" {
  description = "Location of the resources to create"
  type        = string
}

## Key Vault variables
variable "key_vault" {
  type = object({
    name                            = string
    enabled_for_disk_encryption     = optional(bool, false)
    enabled_for_deployment          = optional(bool, false)
    enabled_for_template_deployment = optional(bool, false)
    enable_rbac_authorization       = optional(bool, true)
    purge_protection                = optional(bool, true)
    soft_delete_retention_days      = optional(number, 30)
    sku                             = optional(string, "standard")
    public_network_access_enabled   = optional(bool, false)
    ip_rules                        = optional(set(string), [])
    subnet_ids                      = optional(set(string), [])
    network_bypass                  = optional(string, "AzureServices")
    cmk_keys_create                 = optional(bool, true)
    cmkrsa_key_name                 = optional(string, "cmkrsa")
    cmkec_key_name                  = optional(string, "cmkec")
    cmk_rotation_period             = optional(string, "P18M")
    cmk_expiry_period               = optional(string, "P2Y")
    cmk_notify_period               = optional(string, "P30D")
    cmk_expiration_date             = optional(string, null)
    tags                            = optional(map(string), {})
  })
}

variable "key_vault_key" {
  type = map(object({
    name            = optional(string, null)
    curve           = optional(string, null)
    size            = optional(number, null)
    type            = optional(string, null)
    opts            = optional(set(string), null)
    expiration_date = optional(string, null)
    not_before_date = optional(string, null)
    rotation_policy = optional(object({
      automatic = optional(object({
        time_after_creation = optional(string, null)
        time_before_expiry  = optional(string, null)
      }), null)
      expire_after         = optional(string, null)
      notify_before_expiry = optional(string, null)
    }), null)
    tags = optional(map(string), {})
  }))
  default     = {}
  description = <<DESCRIPTION
This map describes the configuration for Azure Key Vault keys.

- `key_vault_id` - (Required) The ID of the Key Vault.
- `key_type` - (Required) The type of the key.
- `key_size` - (Required) The size of the key.
- `key_opts` - (Required) The key operations that are permitted.

Example Inputs:

```hcl
  key_vault_key = {
    key_rsa = {
      type = "RSA"
      size = 4096
      opts = ["encrypt", "decrypt", "sign", "verify", "wrapKey", "unwrapKey"]
    }
    key_ec = {
      type = "EC"
      curve = "P-256"
      opts = ["sign", "verify"]
    }
  }
```
DESCRIPTION
}


## Boot Diag storage account variables
variable "boot_diag_storage_account" {
  description = "Configure a Boot diagnostics Storage Account for the subscription, Boot Diagnostics Storage Accounts must be publically accessible, do not support Zone Redundant Storage and do not support storage tiering settings"
  type = object({
    name                              = string
    account_tier                      = optional(string, "Standard")
    account_replication_type          = optional(string, "LRS")
    access_tier                       = optional(string, "Hot")
    infrastructure_encryption_enabled = optional(bool, true)
    cmk_encryption_enabled            = optional(bool, false)
    system_assigned_identity_enabled  = optional(bool, false)
    user_assigned_identities          = optional(set(string), [])
    ip_rules                          = optional(set(string), null)
    storage_management_policy = optional(object({
      blob_delete_retention_days      = optional(number, 90)
      container_delete_retention_days = optional(number, 90)
    }), null)
    immutability_policy = optional(object({
      state                         = optional(string, "Unlocked")
      allow_protected_append_writes = optional(bool, true)
      period_since_creation_in_days = optional(number, 14)
    }), null)
    tags = optional(map(string), {})
  })
  default = null
  validation {
    condition     = var.boot_diag_storage_account == null ? true : contains(["LRS", "GRS", "RAGRS"], var.boot_diag_storage_account.account_replication_type)
    error_message = "boot diagnostic storage accounts must be either 'LRS', 'GRS' or 'RAGRS'"
  }
}

variable "container_registry" {
  description = "Configuration for the Azure Container Registry"
  type = object({
    name                             = string
    sku                              = optional(string, "Premium")
    anonymous_pull_enabled           = optional(bool, false)
    quarantine_policy_enabled        = optional(bool, false)
    admin_enabled                    = optional(bool, false)
    public_network_access_enabled    = optional(bool, false)
    pe_subnet                        = optional(string, null)
    network_rule_bypass_option       = optional(string, "None")
    enable_trust_policy              = optional(bool, false)
    export_policy_enabled            = optional(bool, false)
    retention_policy_in_days         = optional(number, 7)
    system_assigned_identity_enabled = optional(bool, false)
    user_assigned_identities         = optional(set(string), [])
    cmk_encryption_enabled           = optional(bool, false)
    cmk_identity_id                  = optional(string, null)
    georeplications = optional(list(object({
      location                  = string
      regional_endpoint_enabled = optional(bool, true)
      zone_redundancy_enabled   = optional(bool, true)
      tags                      = optional(map(any), null)
    })), [])
    zone_redundancy_enabled = optional(bool, true)
    role_assignments = optional(map(object({
      principal_id         = string
      role_definition_name = string
    })))
    tags = optional(map(string), {})
  })
  default = null
}

variable "tags" {
  description = "A map of tags to assign to the resource."
  type        = map(string)
  default     = {}
}
