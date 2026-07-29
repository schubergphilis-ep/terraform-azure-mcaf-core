terraform {
  required_version = ">= 1.7"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4"
    }
  }
}

provider "azurerm" {
  subscription_id = "00000000-0000-0000-0000-000000000000"
  features {}
}

resource "azurerm_resource_group" "network" {
  name     = "example-network-rg"
  location = "West Europe"
}

resource "azurerm_virtual_network" "example" {
  name                = "example-acr-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.network.location
  resource_group_name = azurerm_resource_group.network.name
}

resource "azurerm_subnet" "example" {
  name                              = "example-acr-pep-subnet"
  resource_group_name               = azurerm_resource_group.network.name
  virtual_network_name              = azurerm_virtual_network.example.name
  address_prefixes                  = ["10.0.1.0/24"]
  private_endpoint_network_policies = "Disabled"
}

module "azure_core" {
  source = "../.."

  resource_group_name = "example-rg"

  key_vault = {
    name = "example-kv"
  }

  container_registry = {
    name = "example-acr"
    # public_network_access_enabled defaults to false, so a private endpoint
    # is created into the subnet below instead of exposing the registry publicly.
    pe_subnet = azurerm_subnet.example.id
  }

  location = "West Europe"
  tags     = { Environment = "Production" }
}
