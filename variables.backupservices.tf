variable "recovery_services_vault" {
  type = object({
    name                             = string
    public_network_access_enabled    = optional(bool, false)
    sku                              = optional(string, "Standard")
    storage_mode_type                = optional(string, "GeoRedundant")
    cross_region_restore_enabled     = optional(bool, false)
    system_assigned_identity_enabled = optional(bool, true)
    user_assigned_identities         = optional(set(string), [])
    cmk_identity_id                  = optional(string, null)
    cmk_encryption_enabled           = optional(bool, false)
    immutability                     = optional(string, null)
    tags                             = optional(map(string), {})
  })
  default = null
}

variable "vm_backup_policy" {
  type = map(object({
    name                           = string
    timezone                       = string
    instant_restore_retention_days = optional(number, null)
    policy_type                    = string
    frequency                      = string

    retention_daily = optional(number, null)

    backup = object({
      time          = string
      hour_interval = optional(number, null)
      hour_duration = optional(number, null)
      weekdays      = optional(list(string), [])
    })

    retention_weekly = optional(object({
      count    = optional(number, 7)
      weekdays = optional(list(string), [])
    }), {})

    retention_monthly = optional(object({
      count             = optional(number, 0)
      weekdays          = optional(list(string), [])
      weeks             = optional(list(string), [])
      days              = optional(list(number), [])
      include_last_days = optional(bool, false)
    }), {})

    retention_yearly = optional(object({
      count             = optional(number, 0)
      months            = optional(list(string), [])
      weekdays          = optional(list(string), [])
      weeks             = optional(list(string), [])
      days              = optional(list(number), [])
      include_last_days = optional(bool, false)
    }), {})
  }))
  default     = {}
  description = <<DESCRIPTION
    A map of objects for backup and retention options.

    - `name` - (Required) The name of the backup policy.
    - `timezone` - (Required) The timezone for the backup policy.
    - `instant_restore_retention_days` - (Optional) The number of days to retain instant restore points.
    - `instant_restore_resource_group` - (Optional) A map of resource group options for instant restore.
        - `prefix` - (Optional) Prefix for the resource group name.
        - `suffix` - (Optional) Suffix for the resource group name.
    - `policy_type` - (Required) The type of the backup policy.
    - `frequency` - (Required) The frequency of the backup. Possible values are Hourly, Daily, and Weekly.

    - `backup` - (Required) Backup options.
        - `time` - (Required) Specify time in a 24-hour format HH:MM. Example: "22:00".
        - `hour_interval` - (Optional) Interval in hours at which backup is triggered. Possible values are 4, 6, 8, and 12. This is used when frequency is Hourly.
        - `hour_duration` - (Optional) Duration of the backup window in hours. Possible values are between 4 and 24. This is used when frequency is Hourly.
        - `weekdays` - (Optional) The days of the week to perform backups on. Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, or Saturday. This is used when frequency is Weekly.

    - `retention_daily` - (Optional) The number of daily backups to retain.
    - `retention_weekly` - (Optional) A map of weekly retention options.
        - `count` - (Optional) The number of weekly backups to retain.
        - `weekdays` - (Optional) The weekdays to retain backups. Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, or Saturday.
    - `retention_monthly` - (Optional) A map of monthly retention options.
        - `count` - (Required) The number of monthly backups to retain. Must be between 1 and 9999.
        - `weekdays` - (Optional) The weekdays to retain backups. Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, or Saturday.
        - `weeks` - (Optional) The weeks of the month to retain backups. Must be one of First, Second, Third, Fourth, Last.
        - `days` - (Optional) The days of the month to retain backups. Must be between 1 and 31.
        - `include_last_days` - (Optional) Include the last day of the month. Defaults to false.
    - `retention_yearly` - (Optional) A map of yearly retention options.
        - `count` - (Required) The number of yearly backups to retain. Must be between 1 and 9999.
        - `months` - (Required) The months of the year to retain backups. Must be one of January, February, March, April, May, June, July, August, September, October, November, or December.
        - `weekdays` - (Optional) The weekdays to retain backups. Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday, or Saturday.
        - `weeks` - (Optional) The weeks of the month to retain backups. Must be one of First, Second, Third, Fourth, Last.
        - `days` - (Optional) The days of the month to retain backups. Must be between 1 and 31.
        - `include_last_days` - (Optional) Include the last day of the month. Defaults to false.

    Example:
      vm_backup_policy = {
        example_policy = {
          name                           = "example_policy"
          timezone                       = "UTC"
          policy_type                    = "VMBkp"
          frequency                      = "Hourly"
          backup = {
            time          = "22:00"
            hour_interval = 6
            hour_duration = 12
          }
          retention_daily = 7
          retention_weekly = {
            count    = 7
            weekdays = ["Monday", "Wednesday"]
          }
          retention_monthly = {
            count    = 5
            days     = [3, 10, 20]
          }
          retention_yearly = {
            count  = 5
            months = ["January", "July"]
            days   = [3, 10, 20]
          }
        }
      }
    DESCRIPTION
}

variable "file_share_backup_policy" {
  type = map(object({
    name            = string
    timezone        = string
    frequency       = string
    retention_daily = optional(number, null)

    backup = object({
      time = string
      hourly = optional(object({
        interval        = number
        start_time      = string
        window_duration = number
      }))
    })

    retention_weekly = optional(object({
      count    = optional(number, 7)
      weekdays = optional(list(string), [])
    }), {})

    retention_monthly = optional(object({
      count             = optional(number, 0)
      weekdays          = optional(list(string), [])
      weeks             = optional(list(string), [])
      days              = optional(list(number), [])
      include_last_days = optional(bool, false)
    }), {})

    retention_yearly = optional(object({
      count             = optional(number, 0)
      months            = optional(list(string), [])
      weekdays          = optional(list(string), [])
      weeks             = optional(list(string), [])
      days              = optional(list(number), [])
      include_last_days = optional(bool, false)
    }), {})
  }))
  default     = {}
  description = <<DESCRIPTION
    A map objects for backup and retation options.

    - `name` - (Optional) The name of the private endpoint. One will be generated if not set.
    - `role_assignments` - (Optional) A map of role assignments to create on the

    - `backup` - (required) backup options.
        - `frequency` - (Required) Sets the backup frequency. Possible values are hourly, Daily and Weekly.
        - `time` - (required) Specify time in a 24 hour format HH:MM. "22:00"
        - `hour_interval` - (Optional) Interval in hour at which backup is triggered. Possible values are 4, 6, 8 and 12. This is used when frequency is hourly. 6
        - `hour_duration` -  (Optional) Duration of the backup window in hours. Possible values are between 4 and 24 This is used when frequency is hourly. 12
        - `weekdays` -  (Optional) The days of the week to perform backups on. Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday. This is used when frequency is Weekly. ["Tuesday", "Saturday"]
    - `retention_daily` - (Optional)
      - `count` -
    - `retantion_weekly` -
      - `count` -
      - `weekdays` -
    - `retantion_monthly` -
      - `count` -  # (Required) The number of monthly backups to keep. Must be between 1 and 9999
      - `weekdays` - (Optional) The weekday backups to retain . Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday.
      - `weeks` -  # (Optional) The weeks of the month to retain backups of. Must be one of First, Second, Third, Fourth, Last.
      - `days` -  # (Optional) The days of the month to retain backups of. Must be between 1 and 31.
      - `include_last_days` -  # (Optional) Including the last day of the month, default to false.
    - `retantion_yearly` -
      - `months` - # (Required) The months of the year to retain backups of. Must be one of January, February, March, April, May, June, July, August, September, October, November and December.
      - `count` -  # (Required) The number of monthly backups to keep. Must be between 1 and 9999
      - `weekdays` - (Optional) The weekday backups to retain . Must be one of Sunday, Monday, Tuesday, Wednesday, Thursday, Friday or Saturday.
      - `weeks` -  # (Optional) The weeks of the month to retain backups of. Must be one of First, Second, Third, Fourth, Last.
      - `days` -  # (Optional) The days of the month to retain backups of. Must be between 1 and 31.
      - `include_last_days` -  # (Optional) Including the last day of the month, default to false.

    example:
      retentions = {
      rest1 = {
        backup = {
          frequency     = "hourly"
          time          = "22:00"
          hour_interval = 6
          hour_duration = 12
          # weekdays      = ["Tuesday", "Saturday"]
        }
        retention_daily = 7
        retention_weekly = {
          count    = 7
          weekdays = ["Monday", "Wednesday"]

        }
        retention_monthly = {
          count = 5
          # weekdays =  ["Tuesday","Saturday"]
          # weeks = ["First","Third"]
          days = [3, 10, 20]
        }
        retention_yearly = {
          count  = 5
          months = []
          # weekdays =  ["Tuesday","Saturday"]
          # weeks = ["First","Third"]
          days = [3, 10, 20]
        }

        }
      }
    DESCRIPTION
}

## Backup Vault variables
# variable "backup_vault" {
#   type = object({
#     name                       = string
#     location                   = string
#     redundancy                 = string
#     immutability               = string // accepted values are "Disabled"", "Locked", "Unlocked"
#     soft_delete_retention_days = number
#     cmk_key_vault_key_id       = optional(string, null)
#   })
#   default = null
# }

# variable "blob_storage_backup_policy" {
#   type = map(object({
#     retention_duration              = string
#     backup_repeating_time_intervals = list(string) // example ["R/2025-02-21T14:00:00+00:00/P1D"]
#   }))
#   default = {}
# }
