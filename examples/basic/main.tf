terraform {
  required_version = ">= 1.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 5"
    }
  }
}

provider "azurerm" {
  features {}
}

module "azure_core" {
  source = "../.."

  resource_group_name = "example-rg"

  key_vault = {
    name = "example-kv"
  }

  container_registry = {
    name                          = "exampleacr"
    public_network_access_enabled = true
  }


  location = "West Europe"
  tags     = { Environment = "Production" }
}
