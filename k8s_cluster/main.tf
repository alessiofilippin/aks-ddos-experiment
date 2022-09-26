resource "azurerm_resource_group" "this" {
  name     = "${var.name_prefix}-aks-ddos-rg"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "this" {
  name                = "${var.name_prefix}-ddos-aks1"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dns_prefix          = "${var.name_prefix}ddosaks1"

  default_node_pool {
    name       = "default"
    node_count = 4
    vm_size    = var.vm_size
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "aks-${var.name_prefix}-DDoS-Setup"
  }
}