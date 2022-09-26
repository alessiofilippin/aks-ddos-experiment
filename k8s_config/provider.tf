terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.14.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.7.0"
    }
  }
}

provider "kubectl" {
  host                   = data.terraform_remote_state.eks_infra.outputs.kube_host
  cluster_ca_certificate = data.terraform_remote_state.eks_infra.outputs.kube_ca_cert
  token                  = data.terraform_remote_state.eks_infra.outputs.kube_password
  load_config_file       = false
}

data "terraform_remote_state" "eks_infra" {
  backend = "azurerm"
  config = {
    resource_group_name  = "tfstate-ddos-exp-rg"
    storage_account_name = "tfstatestoreddosexp"
    container_name       = "tf-state"
    key                  = "tf-k8s-cluster.tfstate"
  }
}

data "terraform_remote_state" "target" {
  backend = "azurerm"
  config = {
    resource_group_name  = "tfstate-ddos-exp-rg"
    storage_account_name = "tfstatestoreddosexp"
    container_name       = "tf-state"
    key                  = "tf-test-target.tfstate"
  }
}

terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-ddos-exp-rg"
    storage_account_name = "tfstatestoreddosexp"
    container_name       = "tf-state"
    key                  = "tf-k8s-cluster-configuration.tfstate"
  }
}