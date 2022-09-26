resource "random_pet" "server" {
  length = 1
}

resource "random_integer" "randomnumber" {
  min = 1
  max = 500
}

resource "azurerm_resource_group" "this" {
  name     = "${var.name_prefix}-squid-rg-${random_pet.server.id}${random_integer.randomnumber.id}"
  location = var.location
}

resource "azurerm_virtual_network" "this" {
  name                = "${var.name_prefix}-squid-vnet-${random_pet.server.id}${random_integer.randomnumber.id}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
}

resource "azurerm_subnet" "this" {
  name                 = "${var.name_prefix}-squid-clusters-${random_pet.server.id}${random_integer.randomnumber.id}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "this" {
  count               = var.number_of_servers
  name                = "${var.name_prefix}-squid-pub-ip${count.index}-${random_pet.server.id}${random_integer.randomnumber.id}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "this" {
  count               = var.number_of_servers
  name                = "${var.name_prefix}-squid-nic${count.index}-${random_pet.server.id}${random_integer.randomnumber.id}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.this.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.this[count.index].id
  }
}

resource "azurerm_linux_virtual_machine" "this" {
  count                           = var.number_of_servers
  name                            = "${var.name_prefix}-squid${count.index}-${random_pet.server.id}${random_integer.randomnumber.id}"
  resource_group_name             = azurerm_resource_group.this.name
  location                        = azurerm_resource_group.this.location
  size                            = "Standard_B2s"
  admin_username                  = "adminuser"
  admin_password                  = var.password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.this[count.index].id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_network_security_group" "this" {
  name                = "${var.name_prefix}-nsg-squid-${random_pet.server.id}${random_integer.randomnumber.id}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name

  security_rule {
    name                       = "AllowAll"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface_security_group_association" "this" {
  count                     = var.number_of_servers
  network_interface_id      = azurerm_network_interface.this[count.index].id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "null_resource" "copy_squid_conf_file" {

  count = var.number_of_servers

  provisioner "file" {
    source      = "${path.module}/install_bash/squid.conf"
    destination = "/tmp/squid.conf"

    connection {
      type     = "ssh"
      user     = "adminuser"
      password = var.password
      host     = azurerm_public_ip.this[count.index].ip_address
    }

  }

  depends_on = [
    azurerm_network_interface_security_group_association.this,
    azurerm_linux_virtual_machine.this
  ]
}

resource "null_resource" "copy_squid_cert_for_bump" {

  count = var.number_of_servers

  provisioner "file" {
    source      = "${path.module}/install_bash/squidCA.pem"
    destination = "/tmp/squidCA.pem"

    connection {
      type     = "ssh"
      user     = "adminuser"
      password = var.password
      host     = azurerm_public_ip.this[count.index].ip_address
    }

  }

  depends_on = [
    azurerm_network_interface_security_group_association.this,
    azurerm_linux_virtual_machine.this
  ]
}

resource "null_resource" "copy_systemd_file" {

  count = var.number_of_servers

  provisioner "file" {
    source      = "${path.module}/install_bash/squid.service"
    destination = "/tmp/squid.service"

    connection {
      type     = "ssh"
      user     = "adminuser"
      password = var.password
      host     = azurerm_public_ip.this[count.index].ip_address
    }

  }

  depends_on = [
    azurerm_network_interface_security_group_association.this,
    azurerm_linux_virtual_machine.this
  ]
}

resource "null_resource" "install_squid" {

  count = var.number_of_servers

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get -y update",
      "sudo apt-get -y upgrade",
      "sudo apt -y install libssl-dev",
      "sudo apt -y install gcc",
      "sudo apt -y install g++",
      "sudo apt -y install build-essential",
      "wget http://www.squid-cache.org/Versions/v5/squid-5.7.tar.gz",
      "tar xzf squid-5.7.tar.gz",
      "cd squid-5.7/",
      "./configure --prefix=/usr --localstatedir=/var --libexecdir=/usr/lib/squid --datadir=/usr/share/squid --sysconfdir=/etc/squid --with-default-user=proxy --with-logdir=/var/log/squid --with-pidfile=/var/run/squid.pid --with-openssl --enable-ssl-crtd --build=x86_64-linux-gnu --host=x86_64-linux-gnu --target=x86_64-linux-gnu",
      "sudo make",
      "sudo make install",
      "sudo mkdir /etc/squid/conf.d",
      "sudo cp -f /tmp/squid.conf /etc/squid/conf.d/squid.conf",
      "sudo cp -f /tmp/squid.conf /etc/squid/squid.conf",
      "sudo cp -f /tmp/squidCA.pem /etc/squid/squidCA.pem",
      "sudo chmod 700 /etc/squid/squidCA.pem",
      "sudo /usr/lib/squid/security_file_certgen -c -s /var/cache/squid/ssl_db -M 4MB",
      "sudo cp /tmp/squid.service /etc/systemd/system/squid.service",
      "sudo chmod a+rwx /var/log/squid",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable squid",
      "sudo systemctl start squid"
    ]

    on_failure = "continue"

    connection {
      type     = "ssh"
      user     = "adminuser"
      password = var.password
      host     = azurerm_public_ip.this[count.index].ip_address
    }

  }

  depends_on = [
    null_resource.copy_squid_conf_file,
    null_resource.copy_squid_cert_for_bump,
    null_resource.copy_systemd_file
  ]
}

// Prepare LB
resource "azurerm_public_ip" "pub_ip_lb" {
  name                = "${var.name_prefix}-lb-pub-ip-${random_pet.server.id}${random_integer.randomnumber.id}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
  allocation_method   = "Static"
}

resource "azurerm_lb" "this" {
  name                = "${var.name_prefix}-lb-${random_pet.server.id}${random_integer.randomnumber.id}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  sku                 = "Standard"
  sku_tier            = "Regional"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.pub_ip_lb.id
  }
}

resource "azurerm_lb_backend_address_pool" "this" {
  loadbalancer_id = azurerm_lb.this.id
  name            = "${var.name_prefix}-pool-${random_pet.server.id}${random_integer.randomnumber.id}"
}

resource "azurerm_lb_backend_address_pool_address" "this" {
  count                   = var.number_of_servers
  name                    = "${var.name_prefix}-pool-${random_pet.server.id}${random_integer.randomnumber.id}-${count.index}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.this.id
  ip_address              = azurerm_linux_virtual_machine.this[count.index].private_ip_address
  virtual_network_id      = azurerm_virtual_network.this.id
}

resource "azurerm_lb_probe" "probe3129" {
  loadbalancer_id = azurerm_lb.this.id
  name            = "3129-running-probe"
  port            = 3129
}

resource "azurerm_lb_rule" "rule3128" {
  loadbalancer_id                = azurerm_lb.this.id
  name                           = "LBRule3129"
  protocol                       = "Tcp"
  frontend_port                  = 3129
  backend_port                   = 3129
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.this.id]
  probe_id                       = azurerm_lb_probe.probe3129.id
  frontend_ip_configuration_name = "PublicIPAddress"
}