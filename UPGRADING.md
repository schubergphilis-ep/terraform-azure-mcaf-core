# Upgrading

## Upgrading to v2.0.0

v2.0.0 has three breaking changes. Check all three:

1. [Requires azurerm v5](#requires-azurerm-v5): update the provider constraint and run `terraform init -upgrade`.
2. [Removed input `soft_delete_enabled`](#removed-input-soft_delete_enabled): remove it from `recovery_services_vault`.
3. [Container registry inputs follow azurerm v5](#container-registry-inputs-follow-azurerm-v5): remove `enable_trust_policy` and rename `regional_endpoint_enabled`.

None of these need `moved` blocks from you; the child modules move or drop what they need in state themselves.
Read [What to expect in the plan](#what-to-expect-in-the-plan) before you apply.

Terraform does not report attributes that an object input doesn't declare, it drops them silently. A
configuration that still sets one of the removed or renamed inputs below therefore keeps planning without
an error, and the setting has no effect. Run the check under
[Am I affected?](#am-i-affected) after you upgrade.

### Requires azurerm v5

The module and the child modules it calls (key vault, recovery services vault, container registry and
their private endpoints) now require `hashicorp/azurerm` `>= 5` (it was `>= 4, < 5.0`). The module no
longer works with azurerm v4.

**What you need to do:**

1. Set the provider constraint in your root module to `>= 5`:

   ```hcl
   terraform {
     required_providers {
       azurerm = {
         source  = "hashicorp/azurerm"
         version = ">= 5"
       }
     }
   }
   ```

2. Run `terraform init -upgrade`. If you commit `.terraform.lock.hcl`, commit the updated file.
3. Read the [azurerm v5 upgrade guide](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/guides/5.0-upgrade-guide).
   It changes other resources in your configuration too, and two of its provider-level changes apply to
   your `provider "azurerm"` block:
   - `resource_provider_registrations` now defaults to `none` instead of `legacy`. Set it to `legacy`
     to keep registering the same resource providers as before, or list the ones you need in
     `resource_providers_to_register`.
   - Enhanced validation of locations and resource providers is off by default and moved into
     `features { enhanced_validation { ... } }`. The `ARM_PROVIDER_ENHANCED_VALIDATION` environment
     variable is gone.

If you can't move to azurerm v5 yet, stay on v1.x: pin this module to `~> 1.0`.

### Removed input `soft_delete_enabled`

`recovery_services_vault.soft_delete_enabled` is removed. The attribute is gone from
`azurerm_recovery_services_vault` in azurerm v5, so the module can't set it any more.

**What you need to do:**

| Your configuration on v1.x | Action |
|---|---|
| `soft_delete_enabled` not set | Nothing. |
| `soft_delete_enabled = true` | Remove the argument from `recovery_services_vault`. |
| `soft_delete_enabled = false` | Remove the argument from `recovery_services_vault`. The module no longer sets soft delete on the vault, so check the vault's soft delete setting in Azure if you rely on it being off. |

### Container registry inputs follow azurerm v5

The container registry module this module calls adopted azurerm v5, which removes one `container_registry`
input and renames another.

#### `enable_trust_policy` is removed

Azure retired the Container Registry content trust feature, and azurerm v5 removed
`trust_policy_enabled`. There is no replacement.

**What you need to do:** remove `enable_trust_policy` from `container_registry`.

```diff
 container_registry = {
   name                = "myacr"
-  enable_trust_policy = true
 }
```

#### `georeplications[*].regional_endpoint_enabled` is now `global_endpoint_routing_enabled`

azurerm v5 replaces `regional_endpoint_enabled` with `global_endpoint_routing_enabled` in the
`georeplications` block.

**What you need to do:** rename the attribute in every entry of `container_registry.georeplications`.

```diff
 container_registry = {
   name = "myacr"
   georeplications = [
     {
       location                        = "northeurope"
-      regional_endpoint_enabled       = false
+      global_endpoint_routing_enabled = false
     }
   ]
 }
```

Do not leave the old name in place: it is dropped silently and `global_endpoint_routing_enabled` falls back
to its default, `true`, whatever you had set before.

### Am I affected?

Run this in your configuration:

```bash
grep -rnE 'soft_delete_enabled|enable_trust_policy|regional_endpoint_enabled' .
```

- **No output**: nothing to do for the removed and renamed inputs.
- **Output**: apply the changes above to every hit that sets one of these inputs on this module.

### What to expect in the plan

Besides the changes above, the child modules change a few resources. You don't need to act on any of
them, but they show up in the plan. A moved or removed resource is not destroyed.

| Resource | Who sees it | What the plan shows |
|---|---|---|
| `module.keyvault_with_cmk.azurerm_key_vault.this` | Everyone | In-place update: `enable_rbac_authorization` becomes `rbac_authorization_enabled` (the provider's rename). No vault or key is replaced. The input `key_vault.enable_rbac_authorization` keeps its name. |
| `module.keyvault_with_cmk.azurerm_role_assignment.this["deploy_admin"]` | Everyone | `has moved to` `azurerm_role_assignment.deployer`: the deploying identity's Key Vault Administrator assignment, not a replacement. |
| `module.keyvault_with_cmk.time_sleep.role_propagation[0]` | Everyone | Created. The key vault module waits 30 seconds for the deployer's role assignment to take effect before it creates keys, so the first apply takes that much longer. `hashicorp/time` becomes a required provider; `terraform init -upgrade` installs it. This module doesn't expose the delay. |
| `module.boot_diag_storage_account[0].azurerm_storage_account_network_rules.this` | `boot_diag_storage_account` is set | Removed from state without being destroyed. The storage account now carries the same network rules inline, so the firewall configuration is untouched. |
| `module.boot_diag_storage_account[0].azurerm_role_assignment.cmk[0]` | `cmk_encryption_enabled = true` and a system-assigned identity | Replaced. The role *Key Vault Crypto Service Encryption User* is now scoped to the CMK key instead of the whole key vault, and the scope of a role assignment can't change in place. |
| `module.boot_diag_storage_account[0].azurerm_storage_account_customer_managed_key.this[0]` | `cmk_encryption_enabled = true` | Its arguments change from `key_vault_id` and `key_name` to `key_vault_key_id` (azurerm v5 removed the old ones). Review this resource in the plan. |
| `module.container_registry[0].azurerm_container_registry.this` | `container_registry.public_network_access_enabled = false` (the default) | In-place update: `data_endpoint_enabled` changes from `false` to `true`. The module now enables the dedicated data endpoint on private registries, which pulls over the private endpoint need. The data endpoint has its own address, so check that your private DNS has a record for it next to the registry record. This module creates no DNS zone group, so that comes from your platform DNS. Public registries are unchanged. |
| `module.recovery_services_vault[0].azurerm_role_assignment.this[0]` | `cmk_encryption_enabled = true` and `system_assigned_identity_enabled = true` (the default) | Replaced if its scope differs. It is now scoped to the CMK key's resource ID. The key the vault encrypts with doesn't change: it was already the versionless key ID. |

If the plan shows other replacements or destroys, first check that you have removed or renamed the
inputs above.
