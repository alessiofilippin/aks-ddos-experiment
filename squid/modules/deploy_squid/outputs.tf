output "lb_id" {
  value = azurerm_lb.this.frontend_ip_configuration[0].id
}

output "pet_name" {
  value = "${random_pet.server.id}${random_integer.randomnumber.id}"
}
