module "deploy_squids" {
  count  = length(var.location_list)
  source = "./modules/deploy_squid"

  name_prefix       = var.name_prefix
  password          = "Welcome123!!"
  location          = var.location_list[count.index]
  number_of_servers = var.number_of_servers
}


resource "azurerm_resource_group" "this" {
  name     = "${var.name_prefix}-rg-global"
  location = "WestEurope"

  depends_on = [
    module.deploy_squids
  ]
}

resource "azurerm_public_ip" "pub_ip_lb" {
  name                = "${var.name_prefix}-lb-pub-ip-global"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  domain_name_label   = "${var.name_prefix}-lb-pub-ip-global"
  sku                 = "Standard"
  sku_tier            = "Global"
  allocation_method   = "Static"
}

resource "azurerm_lb" "this" {
  name                = "${var.name_prefix}-lb-global"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
  sku_tier            = "Global"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.pub_ip_lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "this" {
  loadbalancer_id = azurerm_lb.this.id
  name            = "${var.name_prefix}-pool-global"
}

resource "azurerm_lb_backend_address_pool_address" "this" {
  count = length(var.location_list) 
  name                                = "pool-for-${module.deploy_squids[count.index].pet_name}"
  backend_address_pool_id             = azurerm_lb_backend_address_pool.this.id
  backend_address_ip_configuration_id = module.deploy_squids[count.index].lb_id
}

resource "azurerm_lb_rule" "rule3129" {
  loadbalancer_id                = azurerm_lb.this.id
  name                           = "LBRule3129"
  protocol                       = "Tcp"
  frontend_port                  = 3129
  backend_port                   = 3129
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.this.id]
  frontend_ip_configuration_name = "PublicIPAddress"
}
