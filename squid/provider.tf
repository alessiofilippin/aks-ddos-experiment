terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.23.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-ddos-exp-rg"
    storage_account_name = "tfstatestoreddosexp"
    container_name       = "tf-state"
    key                  = "tf-squids.tfstate"
  }
}